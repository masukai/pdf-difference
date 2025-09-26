const fetchFormAfter = document.querySelector(".fetchForm_after");
const btnAfter = document.querySelector(".btn_after");
const urlAfter =
  "https://7b68yuirfk.execute-api.ap-northeast-1.amazonaws.com/prod/fileUploader";

const postFetchAfter = () => {
  let formData = new FormData(fetchFormAfter);
  for (let value of formData.entries()) {
    console.log(value);
  }

  fetch(urlAfter, {
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

btnAfter.addEventListener("click", postFetchAfter, false);
