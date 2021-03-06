server {
	# Ports to listen on, uncomment one.
	listen 443 ssl http2;
	listen [::]:443 ssl http2;

	# Server name to listen for
	server_name multisite-subdirectory.com;

	# Path to document root
	root /home/multisite-subdirectory.com/public_html;

	# Paths to certificate files.
	ssl_certificate /etc/letsencrypt/live/multisite-subdirectory.com/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/multisite-subdirectory.com/privkey.pem;

	# File to be used as index
	index index.php;

	# Overrides logs defined in nginx.conf, allows per site logs.
	access_log /home/multisite-subdirectory.com/logs/access.log;
	error_log /home/multisite-subdirectory.com/logs/error.log;

	# Default server block rules
	include global/server/defaults.conf;

	# SSL rules
	include global/server/ssl.conf;

	# Multisite subdirectory install
	include global/server/multisite-subdirectory.conf;

	location / {
		try_files $uri $uri/ /index.php?$args;
	}

	location ~ \.php$ {
		try_files $uri =404;
		include global/fastcgi-params.conf;

		# Use the php pool defined in the upstream variable.
		# See global/php-pool.conf for definition.
		fastcgi_pass   $upstream;
	}

	# Rewrite robots.txt
	rewrite ^/robots.txt$ /index.php last;
}

# Redirect http to https
server {
	listen 80;
	listen [::]:80;
	server_name multisite-subdirectory.com www.multisite-subdirectory.com;

	return 301 https://multisite-subdirectory.com$request_uri;
}

# Redirect www to non-www
server {
	listen 443;
	listen [::]:443;
	server_name www.multisite-subdirectory.com;

	return 301 https://multisite-subdirectory.com$request_uri;
}
