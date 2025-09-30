@'
# Postman E2E Shop

## Quick start
```powershell
docker compose up -d
newman run postman\shop.postman_collection.json -e postman\dev.postman_environment.json -r cli

API: http://localhost:3001/products
Verify: http://localhost:4000/verify/order/test
Mailpit: http://localhost:8025
'@ | Set-Content -Encoding UTF8 README.md
