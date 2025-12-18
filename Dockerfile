from python:trixie
RUN apt update && apt install -y rsync sshpass
RUN pip install poetry
WORKDIR /src/remarks
#RUN git clone https://github.com/alwessel/remarks.git /src/remarks
COPY . /src/remarks
RUN poetry lock
RUN poetry install
ENTRYPOINT ["poetry", "run", "remarks"]
CMD ["--log_level", "DEBUG"]