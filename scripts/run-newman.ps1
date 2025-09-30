newman run postman\shop.postman_collection.json `
  -e postman\dev.postman_environment.json `
  -r cli,htmlextra --reporter-htmlextra-export newman-report.html
