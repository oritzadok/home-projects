FROM python:3.12-slim

WORKDIR /usr/src/app

COPY requirements.txt ./
# Reduce image size by not including cached files, and also force fresh install
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN useradd appuser -u 1001 --user-group
USER appuser
# Note: ports below 1024 are privileged ports and can be used by users with root permission.
# But since Flask default port is 5000 then it's fine


CMD ["python", "app.py"]
