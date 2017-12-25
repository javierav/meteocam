# Meteocam

Este proyecto sube capturas de vídeo de una cámara IP a un bucket Amazon S3, manteniendo un
histórico de las subidas mediante una estructuras de carpetas adecuada.


## Requisitos

* Cámara IP que publique en una URL una captura de la imagen actual.
* Una cuenta de Amazon Web Services.


## Instalación

Este proyecto funciona con Ruby `2.4.3`. Para instalar las dependencias mediante Bundler:

```
$ bundle install
```

## Configuración de Amazon S3

Para alojar las capturas de la cámara, usaremos el almacenamiento de objetos de Amazon. En primer
lugar crearemos un bucket con el nombre que queramos y le asignaremos la siguiente política:

```json
{
  "Version": "2012-10-17",
  "Statement": [
   {
     "Sid": "AddPerm",
     "Effect": "Allow",
     "Principal": "*",
     "Action": "s3:GetObject",
     "Resource": "arn:aws:s3:::bucket-name/*"
   }
  ]
}
```

Mediante esta política le indicamos que para cualquier objeto contenido en nuestro bucket se
permite realizar la operación `GetObject`, que es la que se ejecuta cuando alguien quiere
descargar un objeto, por lo que todos nuestras capturas subidas serán accesibles a cualquiera.

En segundo lugar, creamos un usuario en IAM con acceso programático, de manera que podamos acceder
usando unas credenciales (key y secret). A este nuevo usuario le insertamos la siguiente política
en línea:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowUserToSeeBucketListInTheConsole",
      "Action": [
        "s3:ListAllMyBuckets"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObjectAcl",
        "s3:PutObjectAcl"
      ],
      "Resource": [
        "arn:aws:s3:::bucket-name"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::bucket-name/*"
      ]
    }
  ]
}
```

Mediante esta política, le damos permiso al usuario para listar todos los buckets de S3, de listar
el contenido del bucket, obtener y editar permisos ACL de todos los objetos contenidos en el bucket
y de subir y bajar objetos al bucket.


## Configuración del código

Para configurar este proyecto se usa un archivo de configuración llamado `config.yml`. Se puede
partir del archivo `config.yml.example` y copiarlo a la ruta válida:

```
$ cp config.yml.example config.yml
```

El archivo de configuración está dividido en dos partes: una sobre la cámara ip y otra sobre
Amazon.

| Clave | Descripción |
| --- | --- |
| camera.url | Dirección a la captura de la cámara IP |
| camera.username | Usuario de acceso |
| camera.password | Contraseña de acceso |
| aws.region | Región de Amazon del bucket |
| aws.key | Llave de acceso al usuario IAM |
| aws.secret | Secreto de acceso al usuario IAM |
| aws.bucket | ID del bucket |


## Ejecución

El objetivo es que el script de este proyecto se ejecute cada minuto mediante CRON, de manera
que se almacene en S3 una captura con ese intervalo de tiempo. Cada hora se almacenarán 60 imágenes,
1440 por día, 10080 a la semana, 40320 por mes y 483840 al año.

La estructura de carpetas sigue el patrón: 

```
<año>/<mes>/<dia>/<hora>/<año><mes><dia><hora><minutos><segundos>-webcam.jpeg
```

Para programar su ejecución usamos el comando `crontab -e` para abrir el editor por defecto del
sistema y editar la entrada de crontab para el usuario actual en el cual hayamos iniciado sesión.

En este proyecto se ha usado una Raspberry Pi que está siempre conectada y con acceso a la misma
red en la que se encuentra la cámara IP. En esa Raspberry se ha instalado *Ruby* usando
[rbenv](https://github.com/rbenv/rbenv), por lo que para que la tarea se ejecute cada minuto, en el
CRON ponemos la siguiente línea:

```
* * * * * /home/pi/.rbenv/shims/ruby /home/pi/meteocam/meteocam.rb
```

La ruta al archivo del proyecto en este caso es `/home/pi/meteocam/meteocam.rb` y deberá cambiarse
para reflejar la ruta de instalación en caso de que sea distinta.


## Licencia

Copyright 2017 Javier Aranda - Publicado bajo una licencia [MIT](LICENSE).
