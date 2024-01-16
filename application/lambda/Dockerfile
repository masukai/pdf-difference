FROM public.ecr.aws/lambda/python:3.8
RUN pip3 install --upgrade pip
RUN pip3 install opencv-python
RUN yum install -y mesa-libGL
RUN pip3 install pdf2image
RUN yum -y install poppler-utils
COPY ./lambda_function/main.py ${LAMBDA_TASK_ROOT}

CMD [ "main.lambda_handler" ]
