sudo date -s "$(wget -qSO- --max-redirect=0 119.23.104.115 2>&1 | grep Date: | cut -d' ' -f5-8)Z"
