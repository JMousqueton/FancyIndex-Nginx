# Fancy Index for Nginx
A fancy file Index for [NGINX](https://www.nginx.com/)

* copy main.xslt to a directory 
* modify your nginx configuration :

```
location / {
    autoindex on;
    autoindex_format xml;
    xslt_stylesheet /your/directory/to/main.xslt path='$uri';
}
```
