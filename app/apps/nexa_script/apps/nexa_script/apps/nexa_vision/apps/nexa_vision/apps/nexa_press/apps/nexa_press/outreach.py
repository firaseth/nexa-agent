import logging
from typing import List

logger = logging.getLogger(__name__)

class Outreach:
    """
    Outreach helper for building and sending campaign messages.
    Replace send logic with real provider integration (SMTP, API).
    """
    def __init__(self, sender: str):
        self.sender = sender

    def create_message(self, subject: str, body: str, recipients: List[str]):
        return {
            "from": self.sender,
            "subject": subject,
            "body": body,
            "recipients": recipients
        }

    def send_campaign(self, message):
        # Placeholder: integrate with an API / SMTP service
        logger.info("Sending campaign to %d recipients", len(message.get("recipients", [])))
        # Simulate success
        return {"status": "ok", "sent": len(message.get("recipients", []))}
