import os
import asyncio
from datetime import datetime
from azure.servicebus.aio import ServiceBusClient
from azure.identity.aio import DefaultAzureCredential
from azure.storage.blob.aio import BlobServiceClient

# Configuration
SERVICEBUS_FULLY_QUALIFIED_NAMESPACE = os.environ["SERVICEBUS_FULLY_QUALIFIED_NAMESPACE"]
QUEUE_NAME                           = "myqueue"
MESSAGE_COUNT                        = int(os.environ["MESSAGE_COUNT"])
STORAGE_ACCOUNT_URL                  = os.environ["STORAGE_ACCOUNT_URL"]
BLOB_CONTAINER_NAME                  = "messages"

credential = DefaultAzureCredential()

async def main():
    async with ServiceBusClient(
        fully_qualified_namespace=SERVICEBUS_FULLY_QUALIFIED_NAMESPACE,
        credential=credential,
        logging_enable=True) as servicebus_client:

        async with BlobServiceClient(STORAGE_ACCOUNT_URL, credential=credential) as blob_service_client:

            receiver = servicebus_client.get_queue_receiver(queue_name=QUEUE_NAME)

            async with receiver:
                received_msgs = await receiver.receive_messages(max_wait_time=5, max_message_count=MESSAGE_COUNT)
                
                for msg in received_msgs:
                    content = str(msg)
                    print("Received: " + content)

                    filename = f"{datetime.now().strftime("%Y-%m-%d-%H-%M-%S")}.txt"

                    blob_client = blob_service_client.get_blob_client(
                        container=BLOB_CONTAINER_NAME, 
                        blob=filename
                    )

                    # Note: Since the requested format is down to the second (SS), processing multiple messages
                    # within the exact same second will result in files overwriting each other.
                    # Consider appending a message ID or counter to the filename.
                    # overwrite=True prevents errors if processing multiple msgs in the same second
                    await blob_client.upload_blob(content, overwrite=True)
                    print(f"Saved message to blob: {filename}")

                    # complete the message so that the message is removed from the queue
                    await receiver.complete_message(msg)

        await credential.close()

asyncio.run(main())