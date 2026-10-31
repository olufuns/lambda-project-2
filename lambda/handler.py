import os
import json
import uuid
import boto3
import logging

# Setup logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# DynamoDB table
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["morays_lambda_notes_table"])

def lambda_handler(event, context):
    # Log the incoming event
    logger.info("Received event: %s", json.dumps(event))

    # Extract HTTP method
    method = event["requestContext"]["http"]["method"]
    path = event.get("rawPath", "")

    # POST - Create a new note
    if method == "POST":
        body = json.loads(event.get("body", "{}"))
        note_id = str(uuid.uuid4())
        item = {"noteId": note_id, "content": body.get("content", "")}

        table.put_item(Item=item)
        logger.info("Created note: %s with content: %s", note_id, item["content"])

        return {"statusCode": 201, "body": json.dumps(item)}

    # GET - Retrieve all notes
    if method == "GET":
        notes = table.scan()["Items"]
        logger.info("Retrieved %d notes", len(notes))
        return {"statusCode": 200, "body": json.dumps(notes)}

    # PUT - Update an existing note
    if method == "PUT":
        body = json.loads(event.get("body", "{}"))
        note_id = body.get("noteId")
        content = body.get("content", "")

        if not note_id:
            logger.warning("PUT request missing noteId")
            return {"statusCode": 400, "body": "Missing noteId"}

        table.update_item(
            Key={"noteId": note_id},
            UpdateExpression="SET content = :c",
            ExpressionAttributeValues={":c": content}
        )
        logger.info("Updated note: %s with new content: %s", note_id, content)
        return {"statusCode": 200, "body": "Updated"}

    # DELETE - Remove a note
    if method == "DELETE":
        body = json.loads(event.get("body", "{}"))
        note_id = body.get("noteId")

        if not note_id:
            logger.warning("DELETE request missing noteId")
            return {"statusCode": 400, "body": "Missing noteId"}

        table.delete_item(Key={"noteId": note_id})
        logger.info("Deleted note: %s", note_id)
        return {"statusCode": 200, "body": "Deleted"}

    # Unsupported method
    logger.warning("Unsupported method: %s", method)
    return {"statusCode": 400, "body": "Unsupported"}