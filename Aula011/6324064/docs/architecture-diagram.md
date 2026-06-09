# Architecture Diagram - TF11

## Fluxo principal
```mermaid
graph LR
  User[Browser] --> CF[CloudFront]
  CF --> S3W[S3 Website Bucket]
  User --> APIGW[API Gateway]
  APIGW --> LambdaContact[Lambda Contact Form]
  LambdaContact --> DDB[DynamoDB Contacts]
  User --> UploadAPI[API Upload URL]
  UploadAPI --> S3A[S3 Assets Bucket uploads/raw]
  S3A --> LambdaImage[Lambda Image Processor]
  LambdaImage --> S3AO[S3 Assets uploads/optimized]
  CF --> S3AO
```

## Decisoes tecnicas
- S3 website bucket separado do bucket de assets para reduzir risco de exposicao indevida.
- CloudFront na frente do website para HTTPS obrigatorio e cache global.
- Lambda de imagem desacoplada por evento S3 para reduzir acoplamento no frontend.
- Formulario persistido em DynamoDB para simplicidade operacional e escala.

## Pontos de validacao
- CloudFront com `ViewerProtocolPolicy=redirect-to-https`
- Bucket website com policy de leitura publica apenas em objetos
- Bucket assets privado com CORS configuravel por origem
- Versionamento habilitado em ambos os buckets
