# 参考
# https://hamham-info.com/2021/09/04/python-pdf-diff/

import shutil
import os
import json
from pathlib import Path
import boto3
import glob
import sys

import numpy as np
import cv2
from pdf2image import convert_from_path

VAR_NAME = os.getenv("VAR_NAME")
s3 = boto3.client("s3")


def lambda_handler(event, context):
    print(event)
    clean_folder()
    add_poppler_path()
    pdf_to_images()
    compare_img()
    find_diff()
    # clean_folder()
    return


def add_poppler_path():
    print("add_poppler_path")
    # poppler/binを環境変数PATHに追加する
    poppler_dir = Path(__file__).parent.absolute() / "poppler/bin"
    os.environ["PATH"] += os.pathsep + str(poppler_dir)
    return


def pdf_to_images():
    print("pdf_to_images")

    objs = get_all_objects_low(VAR_NAME + "-input-bucket")

    for _, obj in enumerate(iter(objs)):
        if obj["Key"].endswith("/"):
            continue
        elif "pdf" in obj["Key"]:
            download_from_s3(
                VAR_NAME + "-input-bucket", obj["Key"], "/tmp/" + obj["Key"]
            )

    j, k = 0, 0
    # PDFファイルのパスを取得し順番に捌いていく
    for x in glob.glob("/tmp/pdf_file_before/*.pdf"):
        pdf_path = Path(x)

        # pdfから画像に変換
        pages = convert_from_path(str(pdf_path), dpi=150)
        # 画像ファイルを１ページずつ保存
        image_dir = Path("/tmp/image_file_before")
        shutil.rmtree(image_dir)
        os.mkdir(image_dir)
        for _, page in enumerate(pages):
            file_name = "{:02d}".format(j + 1) + ".jpg"
            image_path = image_dir / file_name
            # JPEGで保存
            page.save(str(image_path), "JPEG")
            j += 1

    for x in glob.glob("/tmp/pdf_file_after/*.pdf"):
        pdf_path = Path(x)

        # pdfから画像に変換
        pages = convert_from_path(str(pdf_path), dpi=150)
        # 画像ファイルを１ページずつ保存
        image_dir = Path("/tmp/image_file_after")
        shutil.rmtree(image_dir)
        os.mkdir(image_dir)
        for _, page in enumerate(pages):
            file_name = "{:02d}".format(k + 1) + ".jpg"
            image_path = image_dir / file_name
            # JPEGで保存
            page.save(str(image_path), "JPEG")
            k += 1
    return


def compare_img():
    print("compare_img")

    image_dir = Path("/tmp/image_file_after")
    for l in range(
        sum(
            os.path.isfile(os.path.join(image_dir, name))
            for name in os.listdir(image_dir)
        )
    ):
        # 参照画像(img_ref)と比較画像(img_comp)の読み込み
        img_ref = cv2.imread("/tmp/image_file_before/{:02d}.jpg".format(l + 1), 1)
        img_comp = cv2.imread("/tmp/image_file_after/{:02d}.jpg".format(l + 1), 1)

        akaze = cv2.AKAZE_create()
        ref_kp, ref_des = akaze.detectAndCompute(img_ref, None)
        comp_kp, comp_des = akaze.detectAndCompute(img_comp, None)

        # 特徴のマッチング
        bf = cv2.BFMatcher()
        matches = bf.knnMatch(ref_des, comp_des, k=2)

        # 正しいマッチングのみ保持
        good_matches = []
        for m, n in matches:
            if m.distance < 0.75 * n.distance:
                good_matches.append([m])

        matches_img = cv2.drawMatchesKnn(
            img_ref,
            ref_kp,
            img_comp,
            comp_kp,
            good_matches,
            None,
            flags=cv2.DrawMatchesFlags_NOT_DRAW_SINGLE_POINTS,
        )

        cv2.imwrite(
            "/tmp/matches/" + "{:02d}.jpg".format(l + 1),
            matches_img,
        )

        # 適切なキーポイントを選択
        ref_matched_kpts = np.float32(
            [ref_kp[m[0].queryIdx].pt for m in good_matches]
        ).reshape(-1, 1, 2)
        sensed_matched_kpts = np.float32(
            [comp_kp[m[0].trainIdx].pt for m in good_matches]
        ).reshape(-1, 1, 2)

        # ホモグラフィを計算
        H, _ = cv2.findHomography(
            ref_matched_kpts, sensed_matched_kpts, cv2.RANSAC, 5.0
        )

        # 画像を変換
        warped_before_img = cv2.warpPerspective(
            img_ref, H, (img_comp.shape[1], img_comp.shape[0])
        )

        cv2.imwrite(
            "/tmp/image_warped_before/" + "{:02d}.jpg".format(l + 1),
            warped_before_img,
        )
    return


def find_diff():
    print("find_diff")

    image_dir = Path("/tmp/image_file_after")
    for l in range(
        sum(
            os.path.isfile(os.path.join(image_dir, name))
            for name in os.listdir(image_dir)
        )
    ):
        # 参照画像(img_ref)と比較画像(img_comp)の読み込み
        img_ref = cv2.imread("/tmp/image_warped_before/{:02d}.jpg".format(l + 1), 1)
        img_comp = cv2.imread("/tmp/image_file_after/{:02d}.jpg".format(l + 1), 1)
        temp_r = img_comp.copy()
        temp_g = img_comp.copy()
        temp_b = img_comp.copy()
        # グレースケース変換
        gray_img_ref = cv2.cvtColor(img_ref, cv2.COLOR_BGR2GRAY)
        gray_img_comp = cv2.cvtColor(img_comp, cv2.COLOR_BGR2GRAY)
        # 単純に画像の引き算
        img_diff = cv2.absdiff(gray_img_ref, gray_img_comp)
        # 差分画像の２値化（閾値が50）
        _, img_bin = cv2.threshold(img_diff, 50, 255, 0)  # 閾値はこちら
        # 2値画像に存在する輪郭の座標値を得る
        contours, _ = cv2.findContours(img_bin, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
        # contoursから一個ずつ輪郭を取り出し、輪郭の位置(x,y)とサイズ(width, height)を得る
        # サイズが 5x5 以上の輪郭を枠で囲う。
        for contour in contours:
            x, y, width, height = cv2.boundingRect(contour)
            if width > 5 or height > 5:
                cv2.rectangle(
                    temp_r,
                    (x - 2, y - 2),
                    (x + width + 2, y + height + 2),
                    (0, 0, 255),
                    2,
                )  # 色の変更可能
                cv2.rectangle(
                    temp_g,
                    (x - 2, y - 2),
                    (x + width + 2, y + height + 2),
                    (0, 255, 0),
                    2,
                )  # 色の変更可能
                cv2.rectangle(
                    temp_b,
                    (x - 2, y - 2),
                    (x + width + 2, y + height + 2),
                    (255, 0, 0),
                    2,
                )  # 色の変更可能
            else:
                continue
        # 差分画像を保存
        cv2.imwrite(
            "/tmp/output-file-red/" + "{:02d}.jpg".format(l + 1),
            temp_r,
        )
        upload_to_s3(
            VAR_NAME + "-output-bucket",
            "output-file-red/" + "{:02d}.jpg".format(l + 1),
            "/tmp/output-file-red/" + "{:02d}.jpg".format(l + 1),
        )
        cv2.imwrite(
            "/tmp/output-file-green/" + "{:02d}.jpg".format(l + 1),
            temp_g,
        )
        upload_to_s3(
            VAR_NAME + "-output-bucket",
            "output-file-green/" + "{:02d}.jpg".format(l + 1),
            "/tmp/output-file-green/" + "{:02d}.jpg".format(l + 1),
        )
        cv2.imwrite(
            "/tmp/output-file-blue/" + "{:02d}.jpg".format(l + 1),
            temp_b,
        )
        upload_to_s3(
            VAR_NAME + "-output-bucket",
            "output-file-blue/" + "{:02d}.jpg".format(l + 1),
            "/tmp/output-file-blue/" + "{:02d}.jpg".format(l + 1),
        )
    return


def clean_folder():
    if os.path.isfile("/tmp/pdf_file_before"):
        shutil.rmtree("/tmp/pdf_file_before")
    os.mkdir("/tmp/pdf_file_before")
    if os.path.isfile("/tmp/pdf_file_after"):
        shutil.rmtree("/tmp/pdf_file_after")
    os.mkdir("/tmp/pdf_file_after")
    if os.path.isfile("/tmp/image_file_before"):
        shutil.rmtree("/tmp/image_file_before")
    os.mkdir("/tmp/image_file_before")
    if os.path.isfile("/tmp/image_file_after"):
        shutil.rmtree("/tmp/image_file_after")
    os.mkdir("/tmp/image_file_after")
    if os.path.isfile("/tmp/image_warped_before"):
        shutil.rmtree("/tmp/image_warped_before")
    os.mkdir("/tmp/image_warped_before")
    if os.path.isfile("/tmp/image_warped_after"):
        shutil.rmtree("/tmp/image_warped_after")
    os.mkdir("/tmp/image_warped_after")
    if os.path.isfile("/tmp/matches"):
        shutil.rmtree("/tmp/matches")
    os.mkdir("/tmp/matches")
    if os.path.isfile("/tmp/output-file-blue"):
        shutil.rmtree("/tmp/output-file-blue")
    os.mkdir("/tmp/output-file-blue")
    if os.path.isfile("/tmp/output-file-green"):
        shutil.rmtree("/tmp/output-file-green")
    os.mkdir("/tmp/output-file-green")
    if os.path.isfile("/tmp/output-file-red"):
        shutil.rmtree("/tmp/output-file-red")
    os.mkdir("/tmp/output-file-red")
    return


def get_all_objects_low(bucket):
    continuation_token = None
    while True:
        if continuation_token is None:
            res = s3.list_objects_v2(Bucket=bucket, MaxKeys=2)
        else:
            res = s3.list_objects_v2(
                Bucket=bucket, ContinuationToken=continuation_token
            )

        # バケットが空の場合Contentsフィールドがなくなる
        if res["KeyCount"] == 0:
            break

        for content in res["Contents"]:
            yield content

        # ContinuationTokenが渡されなかったらそこで終わり
        continuation_token = res.get("NextContinuationToken")
        if continuation_token is None:
            break


def download_from_s3(bucket, s3_key, file_path):
    s3.download_file(bucket, s3_key, file_path)
    return


def upload_to_s3(bucket, s3_key, file_path):
    s3.upload_file(file_path, bucket, s3_key)
    return
