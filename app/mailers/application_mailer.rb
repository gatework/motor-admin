# frozen_string_literal: true

# 邮件基类，统一管理后台系统邮件的默认发件人与布局。
class ApplicationMailer < ActionMailer::Base
  default from: 'webank@139.com'
  layout 'mailer'
end
