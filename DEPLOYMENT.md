# Finance App Deployment Guide

## Quick Deployment Steps for EC2

### Prerequisites
- Ubuntu EC2 instance (t2.micro or larger)
- SSH access to your EC2 instance
- Security group with ports 22 (SSH), 80 (HTTP), and optionally 443 (HTTPS) open

### Step 1: Connect to EC2
```bash
ssh -i your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

### Step 2: Upload Files
From your local machine, upload the project:
```bash
scp -i your-key.pem -r finance-app/ ubuntu@YOUR_EC2_PUBLIC_IP:/home/ubuntu/
```

### Step 3: Create .env File on Server
SSH into your EC2 and create the .env file:
```bash
cd /home/ubuntu/finance-app
nano .env
# Add your OpenAI API key:
# openai_key=your-actual-api-key-here
```

### Step 4: Run Deployment Script
```bash
cd /home/ubuntu/finance-app
chmod +x deploy.sh
./deploy.sh
```

### Step 5: Verify Deployment
Your app should now be running! Access it at:
```
http://YOUR_EC2_PUBLIC_IP
```

## Manual Deployment (Alternative)

If you prefer manual setup:

1. **Install dependencies:**
```bash
sudo apt update
sudo apt install python3-pip python3-venv nginx
```

2. **Set up Python environment:**
```bash
cd /home/ubuntu/finance-app
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

3. **Start with Gunicorn:**
```bash
gunicorn --config gunicorn_config.py app:app
```

4. **Configure Nginx** (see nginx config in deploy.sh)

5. **Set up systemd service** for auto-start on reboot

## Troubleshooting

### Check if app is running:
```bash
sudo systemctl status finance-app
```

### View logs:
```bash
sudo journalctl -u finance-app -f
```

### Restart app:
```bash
sudo systemctl restart finance-app
```

### Check Nginx:
```bash
sudo systemctl status nginx
sudo nginx -t  # Test configuration
```

## Security Notes

1. **Never commit .env file** - It's in .gitignore for security
2. **Use HTTPS in production** - Consider Let's Encrypt for free SSL
3. **Update security groups** - Only allow necessary ports
4. **Keep system updated** - Run `sudo apt update && sudo apt upgrade` regularly

## Updating the App

To update your app after changes:

1. Upload new files to EC2
2. SSH into EC2
3. Activate virtual environment: `source /home/ubuntu/finance-app/venv/bin/activate`
4. Install any new dependencies: `pip install -r requirements.txt`
5. Restart the service: `sudo systemctl restart finance-app`