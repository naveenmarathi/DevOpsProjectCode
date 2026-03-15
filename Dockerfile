# -------- Stage 1: Build the Go binary --------
FROM golang:1.22 AS builder

# Set working directory
WORKDIR /app

# Copy go modules
COPY go.mod ./

# Download dependencies
RUN go mod download

# Copy all project files
COPY . .

# Build the Go application
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o main .

# -------- Stage 2: Minimal runtime image --------
FROM gcr.io/distroless/base

# Set working directory
WORKDIR /

# Copy compiled binary
COPY --from=builder /app/main .

# Copy static files (HTML pages)
COPY --from=builder /app/static ./static

# Expose application port
EXPOSE 8080

# Run the application
CMD ["./main"]
