FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HOST=0.0.0.0

WORKDIR /app
COPY main.py ./main.py

RUN useradd --system --uid 10001 appuser
USER appuser

CMD ["python", "main.py"]