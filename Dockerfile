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

# Railway will set PORT environment variable
CMD ["centrifugo", "--config=config.json"]
