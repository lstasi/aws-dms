FROM public.ecr.aws/lambda/python:3.8
# Set application working directory
WORKDIR /usr/src/app
# Install requirements
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
# Install application
COPY src/app.py ./
# Run application
CMD python app.py