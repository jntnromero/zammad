# encoding: utf-8
require 'test_helper'

class EmailHelperTest < ActiveSupport::TestCase

  test 'a mx_records' do

    domain = 'znuny.com'
    mx_domains = EmailHelper.mx_records(domain)
    assert_equal('arber.znuny.com', mx_domains[0])

  end

  test 'a email parser test' do

    user, domain = EmailHelper.parse_email('somebody@example.com')
    assert_equal('somebody', user)
    assert_equal('example.com', domain)

    user, domain = EmailHelper.parse_email('somebody+test@example.com')
    assert_equal('somebody+test', user)
    assert_equal('example.com', domain)

    user, domain = EmailHelper.parse_email('somebody+testexample.com')
    assert_not(user)
    assert_not(domain)

  end

  test 'provider test' do
    email = 'linus@kernel.org'
    password = 'some_pw'
    map = EmailHelper.provider(email, password)

    assert_equal('imap', map[:google][:inbound][:adapter])
    assert_equal('imap.gmail.com', map[:google][:inbound][:options][:host])
    assert_equal(993, map[:google][:inbound][:options][:port])
    assert_equal(email, map[:google][:inbound][:options][:user])
    assert_equal(password, map[:google][:inbound][:options][:password])

    assert_equal('smtp', map[:google][:outbound][:adapter])
    assert_equal('smtp.gmail.com', map[:google][:outbound][:options][:host])
    assert_equal(25, map[:google][:outbound][:options][:port])
    assert_equal(true, map[:google][:outbound][:options][:start_tls])
    assert_equal(email, map[:google][:outbound][:options][:user])
    assert_equal(password, map[:google][:outbound][:options][:password])

  end

  test 'provider_inbound_mx' do

    email = 'linus@znuny.com'
    password = 'some_pw'
    user, domain = EmailHelper.parse_email(email)
    mx_domains = EmailHelper.mx_records(domain)
    map = EmailHelper.provider_inbound_mx(user, email, password, mx_domains)

    assert_equal('imap', map[0][:adapter])
    assert_equal('arber.znuny.com', map[0][:options][:host])
    assert_equal(993, map[0][:options][:port])
    assert_equal(user, map[0][:options][:user])
    assert_equal(password, map[0][:options][:password])

    assert_equal('imap', map[1][:adapter])
    assert_equal('arber.znuny.com', map[1][:options][:host])
    assert_equal(993, map[1][:options][:port])
    assert_equal(email, map[1][:options][:user])
    assert_equal(password, map[1][:options][:password])

  end

  test 'provider_inbound_guess' do

    email = 'linus@znuny.com'
    password = 'some_pw'
    user, domain = EmailHelper.parse_email(email)
    map = EmailHelper.provider_inbound_guess(user, email, password, domain)

    assert_equal('imap', map[0][:adapter])
    assert_equal('mail.znuny.com', map[0][:options][:host])
    assert_equal(993, map[0][:options][:port])
    assert_equal(user, map[0][:options][:user])
    assert_equal(password, map[0][:options][:password])

    assert_equal('imap', map[1][:adapter])
    assert_equal('mail.znuny.com', map[1][:options][:host])
    assert_equal(993, map[1][:options][:port])
    assert_equal(email, map[1][:options][:user])
    assert_equal(password, map[1][:options][:password])

  end

  test 'provider_outbound_mx' do

    email = 'linus@znuny.com'
    password = 'some_pw'
    user, domain = EmailHelper.parse_email(email)
    mx_domains = EmailHelper.mx_records(domain)
    map = EmailHelper.provider_outbound_mx(user, email, password, mx_domains)

    assert_equal('smtp', map[0][:adapter])
    assert_equal('arber.znuny.com', map[0][:options][:host])
    assert_equal(25, map[0][:options][:port])
    assert_equal(true, map[0][:options][:start_tls])
    assert_equal(user, map[0][:options][:user])
    assert_equal(password, map[0][:options][:password])

    assert_equal('smtp', map[1][:adapter])
    assert_equal('arber.znuny.com', map[1][:options][:host])
    assert_equal(25, map[1][:options][:port])
    assert_equal(true, map[1][:options][:start_tls])
    assert_equal(email, map[1][:options][:user])
    assert_equal(password, map[1][:options][:password])

  end

  test 'provider_outbound_guess' do

    email = 'linus@znuny.com'
    password = 'some_pw'
    user, domain = EmailHelper.parse_email(email)
    map = EmailHelper.provider_outbound_guess(user, email, password, domain)

    assert_equal('smtp', map[0][:adapter])
    assert_equal('mail.znuny.com', map[0][:options][:host])
    assert_equal(25, map[0][:options][:port])
    assert_equal(true, map[0][:options][:start_tls])
    assert_equal(user, map[0][:options][:user])
    assert_equal(password, map[0][:options][:password])

    assert_equal('smtp', map[1][:adapter])
    assert_equal('mail.znuny.com', map[1][:options][:host])
    assert_equal(25, map[1][:options][:port])
    assert_equal(true, map[1][:options][:start_tls])
    assert_equal(email, map[1][:options][:user])
    assert_equal(password, map[1][:options][:password])

  end

  test 'z probe_inbound' do

    # network issues
    result = EmailHelper::Probe.inbound(
      adapter: 'imap',
      options: {
        host: 'not_existsing_host',
        port: 993,
        ssl: true,
        user: 'some@example.com',
        password: 'password',
      }
    )

    assert_equal('invalid', result[:result])
    assert_equal('Hostname not found!', result[:message_human])
    assert_equal('not_existsing_host', result[:settings][:options][:host])

    result = EmailHelper::Probe.inbound(
      adapter: 'imap',
      options: {
        host: 'www.zammad.com',
        port: 993,
        ssl: true,
        user: 'some@example.com',
        password: 'password',
      }
    )
    assert_equal('invalid', result[:result])
    assert_equal('Connection refused!', result[:message_human])
    assert_equal('www.zammad.com', result[:settings][:options][:host])

    result = EmailHelper::Probe.inbound(
      adapter: 'imap',
      options: {
        host: '172.42.42.42',
        port: 993,
        ssl: true,
        user: 'some@example.com',
        password: 'password',
      }
    )
    assert_equal('invalid', result[:result])
    assert_equal('Host not reachable!', result[:message_human])
    assert_equal('172.42.42.42', result[:settings][:options][:host])

    # gmail
    result = EmailHelper::Probe.inbound(
      adapter: 'imap',
      options: {
        host: 'imap.gmail.com',
        port: 993,
        ssl: true,
        user: 'some@example.com',
        password: 'password',
      }
    )
    assert_equal('invalid', result[:result])
    assert_equal('Authentication failed, username incorrect!', result[:message_human])
    assert_equal('imap.gmail.com', result[:settings][:options][:host])

    result = EmailHelper::Probe.inbound(
      adapter: 'imap',
      options: {
        host: 'imap.gmail.com',
        port: 993,
        ssl: true,
        user: 'frank.tailor05@googlemail.com',
        password: 'password',
      }
    )
    assert_equal('invalid', result[:result])
    assert_equal('Authentication failed, invalid credentials!', result[:message_human])
    assert_equal('imap.gmail.com', result[:settings][:options][:host])

    # dovecot
    result = EmailHelper::Probe.inbound(
      adapter: 'imap',
      options: {
        host: 'arber.znuny.com',
        port: 993,
        ssl: true,
        user: 'some@example.com',
        password: 'password',
      }
    )
    assert_equal('invalid', result[:result])
    assert_equal('Authentication failed!', result[:message_human])
    assert_equal('arber.znuny.com', result[:settings][:options][:host])

    # realtest - test I
    if !ENV['EMAILHELPER_MAILBOX_1']
      raise "Need EMAILHELPER_MAILBOX_1 as ENV variable like export EMAILHELPER_MAILBOX_1='unittestemailhelper01@znuny.com:somepass'"
      return
    end
    mailbox_user     = ENV['EMAILHELPER_MAILBOX_1'].split(':')[0]
    mailbox_password = ENV['EMAILHELPER_MAILBOX_1'].split(':')[1]
    user, domain = EmailHelper.parse_email(mailbox_user)
    result = EmailHelper::Probe.inbound(
      adapter: 'imap',
      options: {
        host: 'arber.znuny.com',
        port: 993,
        ssl: true,
        user: user,
        password: mailbox_password,
      }
    )
    assert_equal('ok', result[:result])

  end

  test 'z probe_outbound' do

    # network issues
    result = EmailHelper::Probe.outbound(
      {
        adapter: 'smtp',
        options: {
          host: 'not_existsing_host',
          port: 25,
          start_tls: true,
          user: 'some@example.com',
          password: 'password',
        }
      },
      'some@example.com',
    )

    assert_equal('invalid', result[:result])
    assert_equal('Hostname not found!', result[:message_human])
    assert_equal('not_existsing_host', result[:settings][:options][:host])

    result = EmailHelper::Probe.outbound(
      {
        adapter: 'smtp',
        options: {
          host: 'www.zammad.com',
          port: 25,
          start_tls: true,
          user: 'some@example.com',
          password: 'password',
        }
      },
      'some@example.com',
    )
    assert_equal('invalid', result[:result])
    assert_equal('Connection refused!', result[:message_human])
    assert_equal('www.zammad.com', result[:settings][:options][:host])

    result = EmailHelper::Probe.outbound(
      {
        adapter: 'smtp',
        options: {
          host: '172.42.42.42',
          port: 25,
          start_tls: true,
          user: 'some@example.com',
          password: 'password',
        }
      },
      'some@example.com',
    )
    assert_equal('invalid', result[:result])
    assert_equal('Host not reachable!', result[:message_human])
    assert_equal('172.42.42.42', result[:settings][:options][:host])

    # gmail
    result = EmailHelper::Probe.outbound(
      {
        adapter: 'smtp',
        options: {
          host: 'smtp.gmail.com',
          port: 25,
          start_tls: true,
          user: 'some@example.com',
          password: 'password',
        }
      },
      'some@example.com',
    )
    assert_equal('invalid', result[:result])
    assert_equal('Authentication failed!', result[:message_human])
    assert_equal('smtp.gmail.com', result[:settings][:options][:host])

    result = EmailHelper::Probe.outbound(
      {
        adapter: 'smtp',
        options: {
          host: 'smtp.gmail.com',
          port: 25,
          start_tls: true,
          user: 'frank.tailor05@googlemail.com',
          password: 'password',
        }
      },
      'some@example.com',
    )
    assert_equal('invalid', result[:result])
    assert_equal('Authentication failed!', result[:message_human])
    assert_equal('smtp.gmail.com', result[:settings][:options][:host])

    # dovecot
    result = EmailHelper::Probe.outbound(
      {
        adapter: 'smtp',
        options: {
          host: 'arber.znuny.com',
          port: 25,
          start_tls: true,
          user: 'some@example.com',
          password: 'password',
        }
      },
      'some@example.com',
    )
    assert_equal('invalid', result[:result])
    assert_equal('Authentication failed!', result[:message_human])
    assert_equal('arber.znuny.com', result[:settings][:options][:host])

    # realtest - test I
    if !ENV['EMAILHELPER_MAILBOX_1']
      raise "Need EMAILHELPER_MAILBOX_1 as ENV variable like export EMAILHELPER_MAILBOX_1='unittestemailhelper01@znuny.com:somepass'"
      return
    end
    mailbox_user     = ENV['EMAILHELPER_MAILBOX_1'].split(':')[0]
    mailbox_password = ENV['EMAILHELPER_MAILBOX_1'].split(':')[1]
    user, domain = EmailHelper.parse_email(mailbox_user)
    result = EmailHelper::Probe.outbound(
      {
        adapter: 'smtp',
        options: {
          host: 'arber.znuny.com',
          port: 25,
          start_tls: true,
          user: user,
          password: mailbox_password,
        }
      },
      mailbox_user,
    )
    assert_equal('ok', result[:result])
  end

  test 'zz probe' do

    result = EmailHelper::Probe.full(
      email: 'invalid_format',
      password: 'somepass',
    )
    assert_equal('invalid', result[:result])
    assert_not(result[:setting])

    # realtest - test I
    if !ENV['EMAILHELPER_MAILBOX_1']
      raise "Need EMAILHELPER_MAILBOX_1 as ENV variable like export EMAILHELPER_MAILBOX_1='unittestemailhelper01@znuny.com:somepass'"
    end
    mailbox_user     = ENV['EMAILHELPER_MAILBOX_1'].split(':')[0]
    mailbox_password = ENV['EMAILHELPER_MAILBOX_1'].split(':')[1]

    result = EmailHelper::Probe.full(
      email: mailbox_user,
      password: mailbox_password,
    )
    assert_equal('ok', result[:result])
    assert_equal('arber.znuny.com', result[:setting][:inbound][:options][:host])
    assert_equal('arber.znuny.com', result[:setting][:outbound][:options][:host])

  end

  test 'zz verify' do

    # realtest - test I
    if !ENV['EMAILHELPER_MAILBOX_1']
      raise "Need EMAILHELPER_MAILBOX_1 as ENV variable like export EMAILHELPER_MAILBOX_1='unittestemailhelper01@znuny.com:somepass'"
    end
    mailbox_user     = ENV['EMAILHELPER_MAILBOX_1'].split(':')[0]
    mailbox_password = ENV['EMAILHELPER_MAILBOX_1'].split(':')[1]
    user, domain = EmailHelper.parse_email(mailbox_user)
    result = EmailHelper::Verify.email(
      inbound: {
        adapter: 'imap',
        options: {
          host: 'arber.znuny.com',
          port: 993,
          ssl: true,
          user: user,
          password: mailbox_password,
        },
      },
      outbound: {
        adapter: 'smtp',
        options: {
          host: 'arber.znuny.com',
          port: 25,
          start_tls: true,
          user: user,
          password: mailbox_password,
        },
      },
      sender: mailbox_user,
    )
    assert_equal('ok', result[:result])
  end

end