# Update Instructions for EC2

To update your EC2 instance to serve the HTML frontend:

## Steps to Update on EC2:

1. **Pull the latest changes:**
```bash
cd /home/ec2-user/finance-app
git pull origin main
```

2. **Restart the Flask app:**
```bash
sudo systemctl restart finance-app
```

3. **Check if the service is running:**
```bash
sudo systemctl status finance-app
```

4. **If there's another service on port 80, check what it is:**
```bash
sudo netstat -tlnp | grep :80
```

5. **If you see "Prepster API", stop it:**
```bash
# Find and stop the conflicting service
sudo systemctl stop prepster  # or whatever the service name is
```

6. **Make sure Nginx is configured correctly:**
```bash
# Check current Nginx config
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

Your app should now be accessible at http://3.108.193.175/ and will show the HTML interface that calls your Python backend.

## Troubleshooting:

If you still see "Prepster API":
1. Check what's running: `sudo lsof -i :80`
2. Check Nginx configs: `ls -la /etc/nginx/conf.d/`
3. Remove conflicting configs: `sudo rm /etc/nginx/conf.d/prepster.conf` (if exists)
4. Restart Nginx: `sudo systemctl restart nginx`