module TransactionHelper
  def process_product_transaction(data_array, transaction_id)    
    data_array.each do |each|
      cart_record = current_user.cart_items.find(each["cart_record"])
      product_record = Product.find(each["prod_record"])

      new_transaction = current_user.product_transactions.create(
        transaction_id: transaction_id,
        prod_name: each["name"],
        prod_desc: each["desc"],
        prod_price: each["price"].to_i,
        prod_quantity: each["quantity"].to_i,
        prod_total: each["total"].to_i
      )

      if new_transaction.persisted?
        product_record.stocks -= each["quantity"].to_i
        product_record.save
        cart_record.destroy!
      else
        raise StandardError
      end
    end
  end

  def process_appointment_transaction(appointment_id, transaction_id)
    appt = Appointment.find(appointment_id)
    slot = Slot.find(appt.slot_id)
    date = slot.date
    time = slot.time

    new_transaction = current_user.appointment_transactions.create(
      transaction_id: transaction_id,
      appt_date: date,
      appt_time: time,
      appt_reason: appt.reason,
      appt_note: appt.note,
      appt_interaction: appt.interaction,
      appt_status: "paid"
    )

    if new_transaction.persisted?
      appt.status = 1
      appt.save
      slot.availability = false
      slot.save
      # maybe dito ikabit yung sa google calendar api
    else
      raise StandardError
    end
  end

  def display_cart_items_to_checkout(param_array)
    result = []
    items = []
    subtotal = []
    
    param_array.each do |param|
      items << current_user.cart_items.find(param)
    end

    items.each do |item|
      item_quantity = item.quantity
      product_record = Product.find(item.product_id)

      data = {
        cart_record: item.id,
        prod_record: product_record.id,
        name: product_record.product_name,
        desc: product_record.product_desc,
        price: product_record.price,
        quantity: item_quantity,
        total: (product_record.price * item_quantity)
      }

      subtotal << product_record.price * item_quantity
      result << data      
    end

    [result, subtotal.reduce(:+)]
    #a shortcut for subtotal.reduce(0) { |amount, total| amount + total }
  end
end
