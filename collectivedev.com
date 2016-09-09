server {
	listen 80;
	server_name collectivedev.com;
	server_name www.collectivedev.com;
	return 301 https://$host$request_uri;
}

server {
	listen 443 ssl;
	server_name collectivedev.com;
	server_name www.collectivedev.com;

	# certs sent to the client in SERVER HELLO are concatenated in ssl_certificate
	ssl_certificate /etc/nginx/collectivedev.crt;
	ssl_certificate_key /etc/nginx/collective.key;
	ssl_session_timeout 1d;
	ssl_session_cache shared:SSL:50m;
	ssl_session_tickets off;

	# Diffie-Hellman parameter for DHE ciphersuites, recommended 2048 bits
	ssl_dhparam /etc/nginx/dhparam.pem;

	# modern configuration. tweak to your needs.
	ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
	ssl_ciphers 'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS';
	ssl_prefer_server_ciphers on;

	# HSTS (ngx_http_headers_module is required) (15768000 seconds = 6 months)
	add_header Strict-Transport-Security max-age=15768000;

	# OCSP Stapling ---
	# fetch OCSP records from URL in ssl_certificate and cache them
	ssl_stapling on;
	ssl_stapling_verify on;

	resolver 8.8.8.8;
	
	location / {
		proxy_set_header        Host $host;
            	proxy_set_header        X-Real-IP $remote_addr;
            	proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            	proxy_set_header        X-Forwarded-Proto $scheme;
            	proxy_pass          http://localhost:3967;
            	proxy_read_timeout  90;
	}
}

