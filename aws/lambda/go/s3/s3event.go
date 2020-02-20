// main.go
package main

import (
	"context"
	"fmt"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
)

var targetBucket string

func handler(ctx context.Context, s3Event events.S3Event) {
	targetBucket = "saidalambdago"
	for _, record := range s3Event.Records {
		fileEvent := record.S3
		fmt.Printf("[%s - %s] Bucket = %s, Key = %s \n", record.EventSource, record.EventTime, fileEvent.Bucket.Name, fileEvent.Object.Key)

		sourceBucket := fileEvent.Bucket.Name
		fileName := fileEvent.Object.Key

		file, err := os.Create("/tmp/" + fileName)
		if err != nil {
			fmt.Println("Cannot create file.")
			return
		}
		defer file.Close()

		sess, _ := session.NewSession()

		// Download the file.
		downloader := s3manager.NewDownloader(sess)
		downloadParams := &s3.GetObjectInput{
			Bucket: aws.String(sourceBucket),
			Key:    aws.String(fileName),
		}
		numBytes, err := downloader.Download(file, downloadParams)
		if err != nil {
			fmt.Printf("Cannot download file %s.\n", fileName)
		}
		fmt.Printf("Download %s with %d bytes.\n", fileName, numBytes)

		// Process the file.

		// Upload the file.
		uploader := s3manager.NewUploader(sess)
		uploadParams := &s3manager.UploadInput{
			Bucket: aws.String(targetBucket),
			Key:    aws.String(fileName),
			Body:   file,
		}

		_, err = uploader.Upload(uploadParams)

		if err != nil {
			fmt.Printf("Cannot upload file %s.\n", fileName)
		}

		fmt.Printf("Successful copy from %s to %s.\n", sourceBucket, targetBucket)
	}
}

func main() {
	// Make the handler available for Remote Procedure Call by AWS Lambda
	lambda.Start(handler)
}
