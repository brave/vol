FROM python:3
COPY requirements.txt /tmp
RUN pip install --no-cache-dir -r /tmp/requirements.txt
COPY --chmod=755 vol /usr/local/bin/
RUN adduser vol
USER vol
ENTRYPOINT ["/usr/local/bin/vol"]
