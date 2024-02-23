# 参考
# https://hamham-info.com/2021/09/04/python-pdf-diff/

import shutil
import os
import json
from pathlib import Path
import boto3
import glob
import sys
import datetime
import time

import numpy as np
import cv2
from pdf2image import convert_from_path

VAR_NAME = "pdf-difference"
s3 = boto3.client("s3")


def lambda_handler(event, context):
    print(event)
    clean_folder()
    add_poppler_path()
    useFlag = False
    response = s3.list_objects_v2(Bucket=VAR_NAME + "-bucket")
    for object in response["Contents"]:
        if "利用中のため使用禁止" in object["Key"]:
            useFlag = True
    if useFlag:
        return
    else:
        DIFF_JST_FROM_UTC = 9
        date_now = datetime.datetime.utcnow() + datetime.timedelta(
            hours=DIFF_JST_FROM_UTC
        )
        folder_name = "利用中のため使用禁止-{}/".format(
            date_now.strftime("%Y年%m月%d日-%H:%M:%S")
        )
        print(folder_name)
        s3.put_object(Bucket=VAR_NAME + "-bucket", Key=folder_name)
        image_num = pdf_to_images()
        compare_img(image_num)
        find_diff(image_num)
        clean_folder()
        time.sleep(120)
        clean_s3()
        s3.delete_object(Bucket=VAR_NAME + "-bucket", Key=folder_name)
        useFlag = False
        return


def add_poppler_path():
    print("add_poppler_path")
    # poppler/binを環境変数PATHに追加する
    poppler_dir = Path(__file__).parent.absolute() / "poppler/bin"
    os.environ["PATH"] += os.pathsep + str(poppler_dir)
    return


def pdf_to_images():
    print("pdf_to_images")
    objs = get_all_objects_low(VAR_NAME + "-bucket")

    for _, obj in enumerate(iter(objs)):
        if obj["Key"].endswith("/"):
            continue
        elif "pdf" in obj["Key"]:
            download_from_s3(
                VAR_NAME + "-bucket",
                obj["Key"],
                "/tmp/" + obj["Key"].replace("/", "-"),
            )
            j = 0
            pdf_path = Path("/tmp/" + obj["Key"].replace("/", "-"))
            # pdfから画像に変換
            pages = convert_from_path(str(pdf_path), dpi=150)
            # 画像ファイルを１ページずつ保存
            if "before" in str(pdf_path):
                pref = "before"
            elif "after" in str(pdf_path):
                pref = "after"
            else:
                continue
            for _, page in enumerate(pages):
                file_name = "/tmp/image-file-{}-{:02d}.jpg".format(pref, j + 1)
                # JPEGで保存
                page.save(str(file_name), "JPEG")
                j += 1
    return j


def compare_img(image_num):
    print("compare_img")
    for l in range(image_num):
        # 参照画像(img_ref)と比較画像(img_comp)の読み込み
        img_ref = cv2.imread("/tmp/image-file-before-{:02d}.jpg".format(l + 1), 1)
        img_comp = cv2.imread("/tmp/image-file-after-{:02d}.jpg".format(l + 1), 1)

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
            "/tmp/" + "matches-{:02d}.jpg".format(l + 1),
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
            "/tmp/" + "image-warped-before-{:02d}.jpg".format(l + 1),
            warped_before_img,
        )
    return


def find_diff(image_num):
    print("find_diff")
    for l in range(image_num):
        # 参照画像(img_ref)と比較画像(img_comp)の読み込み
        img_ref = cv2.imread("/tmp/image-warped-before-{:02d}.jpg".format(l + 1), 1)
        img_comp = cv2.imread("/tmp/image-file-after-{:02d}.jpg".format(l + 1), 1)
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
            "/tmp/" + "output-file-red-{:02d}.jpg".format(l + 1),
            temp_r,
        )
        upload_to_s3(
            VAR_NAME + "-bucket",
            "result/output-file-red/" + "{:02d}.jpg".format(l + 1),
            "/tmp/" + "output-file-red-{:02d}.jpg".format(l + 1),
        )
        cv2.imwrite(
            "/tmp/" + "output-file-green-{:02d}.jpg".format(l + 1),
            temp_g,
        )
        upload_to_s3(
            VAR_NAME + "-bucket",
            "result/output-file-green/" + "{:02d}.jpg".format(l + 1),
            "/tmp/" + "output-file-green-{:02d}.jpg".format(l + 1),
        )
        cv2.imwrite(
            "/tmp/" + "output-file-blue-{:02d}.jpg".format(l + 1),
            temp_b,
        )
        upload_to_s3(
            VAR_NAME + "-bucket",
            "result/output-file-blue/" + "{:02d}.jpg".format(l + 1),
            "/tmp/" + "output-file-blue-{:02d}.jpg".format(l + 1),
        )
    return


def clean_folder():
    print("clean_folder")
    for file in glob.glob("/tmp/*.pdf"):
        os.remove(file)
    for file in glob.glob("/tmp/*.jpg"):
        os.remove(file)
    return


def clean_s3():
    print("clean_s3")
    response = s3.list_objects_v2(Bucket=VAR_NAME + "-bucket")
    for object in response["Contents"]:
        if (".pdf" in object["Key"]) or (".jpg" in object["Key"]):
            s3.delete_object(
                Bucket=VAR_NAME + "-bucket", Key="{}".format(object["Key"])
            )
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
