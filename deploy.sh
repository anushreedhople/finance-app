#!/bin/bash

echo "=== Finance App Deployment Script ==="
echo "This script will deploy your Flask app on Ubuntu EC2"
echo ""

# Update system
echo "1. Updating system packages..."
sudo apt update
sudo apt upgrade -y

# Install Python and dependencies
echo "2. Installing Python and system dependencies..."
sudo apt install -y python3-pip python3-venv nginx

# Create app directory
echo "3. Setting up application directory..."
cd /home/ubuntu
if [ -d "finance-app" ]; then
    echo "Backing up existing app..."
    sudo mv finance-app finance-app.backup.$(date +%Y%m%d_%H%M%S)
fi

# Clone or copy the app (assuming files are uploaded)
mkdir -p finance-app
cd finance-app

# Create virtual environment
echo "4. Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python packages
echo "5. Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Set up systemd service
echo "6. Setting up systemd service..."
sudo cp finance-app.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable finance-app
sudo systemctl start finance-app

# Configure Nginx
echo "7. Configuring Nginx..."
sudo tee /etc/nginx/sites-available/finance-app > /dev/null <<EOF
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

# Enable the site
sudo ln -sf /etc/nginx/sites-available/finance-app /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

# Configure firewall
echo "8. Configuring firewall..."
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

echo ""
echo "=== Deployment Complete! ==="
echo "Your app should now be accessible at http://YOUR_EC2_PUBLIC_IP"
echo ""
echo "Useful commands:"
echo "  - Check app status: sudo systemctl status finance-app"
echo "  - View app logs: sudo journalctl -u finance-app -f"
echo "  - Restart app: sudo systemctl restart finance-app"
echo "  - Check nginx status: sudo systemctl status nginx"