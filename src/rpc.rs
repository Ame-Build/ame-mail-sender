use ame_bus::simple_push::SimplestNatsMessage;
use ame_bus::NatsJsonMessage;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum MailType {
    PlainText,
    Html,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct MailSend {
    pub send_from: String,
    pub send_to: String,
    pub subject: String,
    pub body: String,
    pub mail_type: MailType,
}

#[async_trait::async_trait]
impl NatsJsonMessage for MailSend {
    fn subject() -> &'static str {
        "ame-mail-sender.send"
    }
}

#[async_trait::async_trait]
impl SimplestNatsMessage for MailSend {}