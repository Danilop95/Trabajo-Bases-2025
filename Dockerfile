# Usa la imagen oficial de PHP 8.1 con Apache
FROM php:8.1-apache

# Instala extensiones para MySQL (PDO)
RUN docker-php-ext-install pdo pdo_mysql

# Activa mod_rewrite (si lo necesitas)
RUN a2enmod rewrite

# Ajustar argumentos para UID y GID (por defecto 1000:1000)
ARG USER_ID=1000
ARG GROUP_ID=1000

# Crea un grupo y usuario "developer" con esos IDs
RUN groupadd --gid $GROUP_ID developer \
 && useradd --uid $USER_ID --gid $GROUP_ID --create-home developer

# Asigna la carpeta de Apache al nuevo usuario
RUN chown -R developer:developer /var/www/html

# Opcionalmente, define el WORKDIR como la carpeta HTML
WORKDIR /var/www/html

# Cambiamos el usuario para evitar correr como root
USER developer

# Expone el puerto 80 de Apache
EXPOSE 80

# El CMD por defecto de php:apache ya es "apache2-foreground", 
# así que no necesitamos redeclararlo, a menos que quieras algo personalizado.
