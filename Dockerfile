From ubuntu:latest
ENV token=""
ENV repo=""
ENV owner=""
RUN apt-get update && apt-get install -y curl golang git python3 python3-pip
RUN go install github.com/google/osv-scanner/cmd/osv-scanner@v1
RUN pip3 install cvss
COPY . /app
ENTRYPOINT ["/app/getSBOM.sh"]
