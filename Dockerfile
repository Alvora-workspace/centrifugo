# Build stage
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o centrifugo .

# Production stage  
FROM alpine:3.21

ARG USER=centrifugo
ARG UID=1000
ARG GID=1000

RUN addgroup -S -g $GID $USER && \
    adduser -S -G $USER -u $UID $USER

RUN apk --no-cache upgrade && \
    apk --no-cache add ca-certificates && \
    update-ca-certificates

USER $USER

WORKDIR /centrifugo

# Copy binary from builder stage
COPY --from=builder /app/centrifugo /usr/local/bin/centrifugo

# Copy config file
COPY config.json ./config.json

# Use environment variables via command line flags
CMD ["sh", "-c", "centrifugo --config=config.json --admin_password=$CENTRIFUGO_ADMIN_PASSWORD --admin_secret=$CENTRIFUGO_ADMIN_SECRET --token_hmac_secret_key=$CENTRIFUGO_TOKEN_SECRET --api_key=$CENTRIFUGO_API_KEY --allowed_origins=$CENTRIFUGO_ALLOWED_ORIGINS"]
