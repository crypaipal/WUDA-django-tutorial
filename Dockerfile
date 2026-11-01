# obraz bazowy: slim - min obraz
FROM python:3.12-slim

# python nie tworzy plikow .pyc (zbedne w kontenerze)
# logi od razu trafiaja na stdout i widac je w "docker logs"
# pip nie trzyma cache, obraz jest mniejszy
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# instalacja bibliotek, warstwa trafia do cache
# i nie jest budowana od nowa, gdy zmienia sie kod aplikacji
COPY requirements.txt .
RUN pip install -r requirements.txt

# copy kodu aplikacji, oprocz plikow z .dockerignore
COPY . .

# zbieranie plikow statycznych (CSS) do katalogu staticfiles/, serwuje je whitenoise
# tymczasowy SECRET_KEY tylko na czas budowania, prawdziwy podajemy przy uruchomieniu
RUN DJANGO_SECRET_KEY=build-only python manage.py collectstatic --noinput

# aplikacja dziala jako zwykly uzytkownik, nie root dla bezpieczenstwa
RUN useradd --create-home appuser
USER appuser

EXPOSE 8000

# produkcyjny serwer WSGI gunicorn zamiast deweloperskiego "manage.py runserver"
# 3 procesy robocze, logi zapytan HTTP na stdout
CMD ["gunicorn", "mysite.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "3", "--access-logfile", "-"]
