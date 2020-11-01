FROM python:3.8-slim

WORKDIR /app/

# Install Poetry and wait for it script
RUN apt-get update && apt-get install -y --no-install-recommends curl && \
    curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | POETRY_HOME=/opt/poetry python && \
    cd /usr/local/bin && \
    ln -s /opt/poetry/bin/poetry && \
    poetry config virtualenvs.create false

# Copy poetry.lock* in case it doesn't exist in the repo
COPY pyproject.toml poetry.lock* /app/

# Install dependencies
RUN poetry install --no-root --no-dev

COPY . /app

RUN curl -sSL https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh -o wait-for-it.sh && chmod +x wait-for-it.sh 

EXPOSE 80

ENTRYPOINT [ "./entrypoint.sh" ]
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "80"]
