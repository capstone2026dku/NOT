const nodemailer = require('nodemailer');

let _transporter = null;

function getTransporter() {
  if (_transporter) return _transporter;

  _transporter = nodemailer.createTransport({
    host: process.env.EMAIL_HOST,
    port: parseInt(process.env.EMAIL_PORT || '587', 10),
    secure: process.env.EMAIL_PORT === '465',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });

  return _transporter;
}

async function sendOtpEmail(toEmail, otp) {
  const from = process.env.EMAIL_FROM || `단밥 <${process.env.EMAIL_USER}>`;

  await getTransporter().sendMail({
    from,
    to: toEmail,
    subject: '[단밥] 이메일 인증번호',
    html: `
      <div style="font-family: 'Apple SD Gothic Neo', 'Noto Sans KR', sans-serif; max-width: 480px; margin: 0 auto; padding: 40px 24px; background: #ffffff;">
        <h2 style="color: #005299; font-size: 22px; margin: 0 0 8px;">단밥</h2>
        <p style="color: #64748B; font-size: 13px; margin: 0 0 32px;">단국인의 든든한 한 끼</p>

        <p style="color: #0F172A; font-size: 15px; margin: 0 0 24px;">
          아래 6자리 인증번호를 입력해주세요.<br/>
          인증번호는 <strong>10분간</strong> 유효합니다.
        </p>

        <div style="background: #F0F4F8; border-radius: 12px; padding: 24px; text-align: center; margin: 0 0 24px;">
          <span style="font-size: 36px; font-weight: 700; letter-spacing: 12px; color: #005299;">${otp}</span>
        </div>

        <p style="color: #94A3B8; font-size: 12px; margin: 0;">
          본인이 요청하지 않은 경우 이 메일을 무시해주세요.
        </p>
      </div>
    `,
  });
}

module.exports = { sendOtpEmail };
