use std::sync::Arc;
use ame_bus::NatsJsonMessage;
use clap::Parser;
use futures_util::StreamExt;
use lettre::{AsyncSmtpTransport, AsyncTransport, Message, Tokio1Executor};
use lettre::message::header::ContentType;
use tracing::{error, info};
use ame_mail_sender::{MailSend, MailType};

mod config;

async fn handle_mail_send(msg: MailSend, mailer: &AsyncSmtpTransport<Tokio1Executor>) -> anyhow::Result<()> {
    let email = Message::builder()
        .from(msg.send_from.parse()?)
        .to(msg.send_to.parse()?)
        .header(match msg.mail_type {
            MailType::Html => ContentType::TEXT_HTML,
            MailType::PlainText => ContentType::TEXT_PLAIN
        })
        .subject(msg.subject)
        .body(msg.body)?;
    mailer.send(email).await?;
    Ok(())
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let args = config::Args::parse();
    let config = config::read_config_file(&args.config_file).await?;
    config::set_tracing_subscriber(config.log_level);
    let nats = async_nats::connect(&config.nats).await?;
    let nats = Arc::new(nats);
    let smtp = AsyncSmtpTransport::<Tokio1Executor>::from_url(&config.smtp_server_url)?.build();
    info!("Mail sender started");
    let mut mail_subscriber = nats.subscribe(MailSend::subject()).await?;
    while let Some(msg) = mail_subscriber.next().await {
        let r = handle_mail_send(MailSend::from_json_bytes(&msg.payload)?, &smtp).await;
        if r.is_err() {
            error!("Failed to send mail: {:?}", r);
        }
    }
    Err(anyhow::anyhow!("Mail sender stopped"))
}
