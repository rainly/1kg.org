require 'digest/md5'
require 'cgi'
require 'iconv'

class GatewayController < ApplicationController
  
  def receive_merchant_info
    vendor = Vendor.find_by_slug(params[:pid])
    key = vendor.sign_key
    amount = params[:productNumber].to_i
    pay_result = false
    @validate = Donation::RequestValidate.new(params, key)
    # TODO 如果找不到 key 如何处理
    if @validate.valid_sign?
      # 创建公益物资记录
      amount.times do |i|
        # 生成密码
        while 1
          stuff_password = UUID.create_random.to_s.gsub("-", "").unpack('axaxaxaxaxaxaxax').join('')
          break unless exist_stuff = Stuff.find_by_code(stuff_password)
        end
        @stuff = Stuff.new( :code => stuff_password,
                           :type_id => vendor.products.find_by_serial(params[:productSerial]).stuff_type.id,
                           :order_id => params[:orderId],
                           :order_time => params[:orderTime],
                           :product_serial => params[:productSerial],
                           :product_number => amount,
                           :deal_id => Time.now.to_i
                          )
        if @stuff.save!
           # 发信
           @donation_url = "http://www.1kg.org/market/validate?password=#{stuff_password}"
           Mailer.deliver_donation(params[:buyerName], params[:buyerEmail], @donation_url)
           
           pay_result = true
        else
           pay_result = false
           logger.info("BUILD STUFF FAIL")
        end                
      end
      
      logger.info ("VALID SIGN!!!!")
      
    else
      logger.info("INVALID SIGN!!!")
      pay_result = false
      
    end
    
    # 此处我认为应该直接跳转到配对页面，用户完成匹配后再返回商家网站。
    redirect_to @donation_url
  end
  
  private
end