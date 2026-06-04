FROM python:3.12-slim

WORKDIR /usr/src/app

# Less frequently changed
COPY requirements.txt ./
# Do not save the downloaded packages locally, since pip is not going to be run again
RUN pip install --no-cache-dir -r requirements.txt

COPY ./app .

CMD ["python", "receiver.py"]