const fetchFormBefore = document.querySelector(".fetchForm_before");
const btnBefore = document.querySelector(".btn_before");
const urlBefore =
  "https://59un175x2g.execute-api.ap-northeast-1.amazonaws.com/prod/fileUploader";

const postFetchBefore = () => {
  let formData = new FormData(fetchFormBefore);
  for (let value of formData.entries()) {
    console.log(value);
  }

  fetch(urlBefore, {
    method: "POST",
    body: formData,
  })
    .then((response) => {
      if (!response.ok) {
        console.log("error!");
      }
      console.log("ok!");
      return response.json();
    })
    .then((data) => {
      console.log(data);
    })
    .catch((error) => {
      console.log(error);
    });
};

btnBefore.addEventListener("click", postFetchBefore, false);
