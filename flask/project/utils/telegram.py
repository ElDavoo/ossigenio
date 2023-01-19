"""
Implement Telegram bot API
"""
import asyncio
import os
import time
from functools import partial

import requests
import json
import random
import datetime
import threading
import logging

from project.models.telegram_users import TelegramUser
from telegram import Update, InlineKeyboardButton, ReplyKeyboardMarkup

from project import db
from project.models.places import Place
from project.models.co2history import co2_history
from project.api.common import plausible_random
from project.utils.datagen import start as datagen_start
from telegram.ext import Updater, CommandHandler, MessageHandler, ApplicationBuilder, ContextTypes


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE, app):
    # Check to see if user is already in the table "telegram_users"
    # If not, add them
    # If yes, do nothing

    # Get the user's id
    user_id = update.effective_user.id

    with app.app_context():
        # Check if user is already in the table
        users = TelegramUser.query.filter_by(telegram_id=user_id).all()

    # If not, say bye
    if len(users) == 0:
        await update.message.reply_text(
            str(user_id) + " non sei registrato, contatta un amministratore per registrarti")
        return

    reply_text = "Sei iscritto a questi posti: \n"
    # Every place handled by user is a button as a ReplyKeyboardMarkup
    buttons = []
    with app.app_context():
        for user in users:
            place = Place.query.filter_by(id=user.place).first()
            buttons.append(InlineKeyboardButton(place.name, callback_data=f"place_{place.id}"))
            if user.soglia != 0:
                reply_text += f"{place.name} - {user.soglia}\n"
    buttons = ReplyKeyboardMarkup([buttons], one_time_keyboard=True, resize_keyboard=True)
    reply_text += "Seleziona un posto per modificare la soglia di CO2"
    # display the buttons
    await update.message.reply_text(reply_text, reply_markup=buttons)


def run(app):
    asyncio.set_event_loop(asyncio.new_event_loop())
    token = os.environ.get('TELEGRAM_TOKEN')
    if token is None:
        raise Exception("TELEGRAM_TOKEN not found in environment variables")
    application = ApplicationBuilder().token(token).build()

    # Add handlers and pass the app context as a parameter
    application.add_handler(CommandHandler('start', partial(start, app=app)))

    application.run_polling(
    )


def stort(app):
    run(app)
