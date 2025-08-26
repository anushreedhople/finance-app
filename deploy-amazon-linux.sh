#!/bin/bash

echo "=== Finance App Deployment Script for Amazon Linux ==="
echo "This script will deploy your Flask app on Amazon Linux EC2"
echo ""

# Update system
echo "1. Updating system packages..."
sudo yum update -y

# Install Python and dependencies
echo "2. Installing Python and system dependencies..."
sudo yum install -y python3 python3-pip nginx

# Set up application directory
echo "3. Setting up application directory..."
cd /home/ec2-user/finance-app

# Create virtual environment
echo "4. Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python packages
echo "5. Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Update service file for ec2-user
echo "6. Creating systemd service file..."
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

# Start the service
echo "7. Starting the application service..."
sudo systemctl daemon-reload
sudo systemctl enable finance-app
sudo systemctl start finance-app

# Configure Nginx
echo "8. Configuring Nginx..."
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

# Start and enable Nginx
echo "9. Starting Nginx..."
sudo systemctl enable nginx
sudo systemctl start nginx

# Configure firewall (if using iptables)
echo "10. Checking security group settings..."
echo "Note: Make sure your EC2 security group allows:"
echo "  - Port 22 (SSH)"
echo "  - Port 80 (HTTP)"
echo "  - Port 443 (HTTPS) if using SSL"

echo ""
echo "=== Deployment Complete! ==="
echo "Your app should now be accessible at http://YOUR_EC2_PUBLIC_IP"
echo ""
echo "Useful commands:"
echo "  - Check app status: sudo systemctl status finance-app"
echo "  - View app logs: sudo journalctl -u finance-app -f"
echo "  - Restart app: sudo systemctl restart finance-app"
echo "  - Check nginx status: sudo systemctl status nginx"
echo ""
echo "IMPORTANT: Don't forget to create .env file with your OpenAI API key!"
echo "  echo 'openai_key=your-key-here' > /home/ec2-user/finance-app/.env"