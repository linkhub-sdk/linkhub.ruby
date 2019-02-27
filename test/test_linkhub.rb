# -*- coding: utf-8 -*-
require 'test/unit'
require_relative '../lib/linkhub.rb'


class LHTest < Test::Unit::TestCase
  LinkID = "TESTER"
  SecretKey = "SwWxqU+0TErBXy/9TVjIPEnI0VTUMMSQZtJf3Ed8q3I="

  ServiceID = "POPBILL_TEST"
  AccessID = "1234567890"
  Scope = ["member","110"]

  def test_01getTime
    auth = Linkhub.instance(LHTest::LinkID, LHTest::SecretKey)
    serverTime = auth.getTime
    assert_not_nil(serverTime)
  end

  def test_02singleton
    auth = Linkhub.instance(LHTest::LinkID, LHTest::SecretKey)
    auth2 = Linkhub.instance(LHTest::LinkID, LHTest::SecretKey)
    assert_equal(auth, auth2, "Linkhub Singleton Instance Failure")
  end

  def test_03getSessionToken
    auth = Linkhub.instance(LHTest::LinkID, LHTest::SecretKey)
    token = auth.getSessionToken(LHTest::ServiceID, LHTest::AccessID, LHTest::Scope)
    puts token['expiration']
    assert_not_nil(token)
  end

  def test_03getSessionTokenError
    assert_raise LinkhubException do
      auth = Linkhub.instance(LHTest::LinkID, "fake_secretkey")
      auth.getSessionToken(LHTest::ServiceID, LHTest::AccessID, LHTest::Scope)
    end
  end

  def test_04LinkIDException
    assert_raise LinkhubException do
      auth = Linkhub.instance("ABCDEDDFF", LHTest::SecretKey)
      auth.getSessionToken(LHTest::ServiceID, LHTest::AccessID, LHTest::Scope)
    end
  end

  def test_05getBalance
    auth = Linkhub.instance(LHTest::LinkID, LHTest::SecretKey)
    token = auth.getSessionToken(LHTest::ServiceID, LHTest::AccessID, LHTest::Scope)['session_token']
    balance = auth.getBalance(token, LHTest::ServiceID)
    assert_not_nil(balance)
  end

  def test_06getPartnerBalance
    auth = Linkhub.instance(LHTest::LinkID, LHTest::SecretKey)
    token = auth.getSessionToken(LHTest::ServiceID, LHTest::AccessID, LHTest::Scope)['session_token']
    balance = auth.getPartnerBalance(token, LHTest::ServiceID)
    assert_not_nil(balance)
  end

  def test_07getBalanceException
    assert_raise LinkhubException do
      auth = Linkhub.instance(LHTest::LinkID, LHTest::SecretKey)
      token = auth.getSessionToken(LHTest::ServiceID, "9999999999", LHTest::Scope)['session_token']
      balance = auth.getBalance(token, LHTest::ServiceID)
      assert_not_nil(balance)
    end
  end

  def test_08getPartnerBalanceException
    assert_raise LinkhubException do
      auth = Linkhub.instance(LHTest::LinkID, LHTest::SecretKey)
      token = auth.getSessionToken(LHTest::ServiceID, "9999999999", LHTest::Scope)['session_token']
      balance = auth.getPartnerBalance(token, LHTest::ServiceID)
      assert_not_nil(balance)
    end
  end

  def test_09getPartnerURL
    auth = Linkhub.instance(LHTest::LinkID, LHTest::SecretKey)
    token = auth.getSessionToken("LHTest::ServiceID", LHTest::AccessID, LHTest::Scope)['session_token']
    url = auth.getPartnerURL(token, LHTest::ServiceID, "CHRG")
    assert_not_nil(url)
    puts url
  end
end
