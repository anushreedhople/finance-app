# Finance App Deployment on Amazon Linux EC2

## Quick Manual Steps (Since you're already on EC2)

### 1. Install Dependencies
```bash
sudo yum update -y
sudo yum install -y python3 python3-pip nginx
```

### 2. Set up Python Virtual Environment
```bash
cd /home/ec2-user/finance-app
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 3. Create .env File
```bash
echo 'openai_key=YOUR_ACTUAL_OPENAI_KEY' > .env
```

### 4. Test the App Manually First
```bash
# With virtual environment activated:
python app.py
# This should start on port 1111
# Press Ctrl+C to stop
```

### 5. Set up Gunicorn Service
```bash
# Create service file
sudo tee /etc/systemd/system/finance-app.service > /dev/null <<EOF
[Unit]
Description=Finance App Flask Application
After=network.target

[Service]
User=ec2-user
Group=ec2-user
WorkingDirectory=/home/ec2-user/finance-app
Environment="PATH=/home/ec2-user/finance-app/venv/bin"
ExecStart=/home/ec2-user/finance-app/venv/bin/gunicorn --config gunicorn_config.py app:app

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable finance-app
sudo systemctl start finance-app

# Check if it's running
sudo systemctl status finance-app
```

### 6. Configure Nginx
```bash
# Create Nginx configuration
sudo tee /etc/nginx/conf.d/finance-app.conf > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl status nginx
```

### 7. Verify Everything is Working
```bash
# Check services
sudo systemctl status finance-app
sudo systemctl status nginx

# Check if app is listening
curl http://localhost:8000

# View logs if needed
sudo journalctl -u finance-app -f
```

### 8. Access Your App
Your app should now be accessible at:
```
http://YOUR_EC2_PUBLIC_IP
```

## Troubleshooting

### If the app doesn't start:
1. Check the logs: `sudo journalctl -u finance-app -f`
2. Make sure .env file exists with your API key
3. Verify virtual environment is set up correctly
4. Check Python version: `python3 --version` (should be 3.7+)

### If Nginx shows 502 Bad Gateway:
1. Check if Gunicorn is running: `sudo systemctl status finance-app`
2. Check if port 8000 is being used: `sudo netstat -tlnp | grep 8000`
3. Restart both services:
   ```bash
   sudo systemctl restart finance-app
   sudo systemctl restart nginx
   ```

### Security Group Settings
Make sure your EC2 security group allows:
- Port 22 (SSH) - from your IP
- Port 80 (HTTP) - from anywhere (0.0.0.0/0)
- Port 443 (HTTPS) - if you plan to add SSL later

## Alternative: Run with the Script
If you want to use the automated script:
```bash
# Upload the new script first, then:
chmod +x deploy-amazon-linux.sh
./deploy-amazon-linux.sh
```