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

import telegram

from project.models.telegram_users import TelegramUser
from telegram import Update, InlineKeyboardButton, ReplyKeyboardMarkup

from project import db
from project.models.places import Place
from project.models.co2history import co2_history
from project.api.common import plausible_random
from project.utils.datagen import start as datagen_start
from telegram.ext import Updater, CommandHandler, MessageHandler, ApplicationBuilder, ContextTypes, ConversationHandler


async def place_change(update: Update, context: ContextTypes.DEFAULT_TYPE, app):
    # Check if the user is already in the database
    if not await is_registered(app, update):
        await update.message.reply_text(
            str(update.effective_user.id) + " non sei registrato, contatta un amministratore per registrarti")
        return
    # Get all places handled by the user
    with app.app_context():
        users = db.session.query(TelegramUser).filter_by(telegram_id=update.effective_user.id).all()
        # Try to get a place from the message and check if it's handled by the user
        # We only have the name of the place, so we have to check if it's in the list of places handled by the user
        # If it is, we get the place id
        place_id = None
        for user in users:
            place = db.session.query(Place).filter_by(id=user.place).first()

            if place.name == update.message.text:
                place_id = place.id
                break
        # If the place is not handled by the user, return
        if place_id is None:
            await update.message.reply_text("Non puoi iscriverti a questo posto")
            return

        # Ask the user to insert the new threshold
        await update.message.reply_text("Inserisci la nuova soglia di CO2")
        context.user_data["place_id"] = place_id

        return 1


async def update_threshold(update: Update, context: ContextTypes.DEFAULT_TYPE, app):
    # Get the place_id from the context
    place_id = context.user_data["place_id"]
    # ╗ Update the threshold in the database
    with app.app_context():
        # filter by telegram_id and place_id
        user = db.session.query(TelegramUser).filter_by(telegram_id=update.effective_user.id, place=place_id).first()
        user.soglia = update.message.text
        db.session.commit()
    await update.message.reply_text("Soglia aggiornata")
    return ConversationHandler.END


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE, app):
    # Check to see if user is already in the table "telegram_users"
    # If not, add them
    # If yes, do nothing

    # Get the user's id
    users = await is_registered(app, update)
    if users is None:
        await update.message.reply_text(
            str(update.effective_user.id) + " non sei registrato, contatta un amministratore per registrarti")
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
    return 0


async def is_registered(app, update):
    user_id = update.effective_user.id
    users = []
    with app.app_context():
        # Check if user is already in the table
        users = db.session.query(TelegramUser).filter_by(telegram_id=user_id).all()

        if len(users) != 0:
            return users
    return None


def run(app):
    asyncio.set_event_loop(asyncio.new_event_loop())
    token = os.environ.get('TELEGRAM_TOKEN')
    if token is None:
        raise Exception("TELEGRAM_TOKEN not found in environment variables")
    application = ApplicationBuilder().token(token).build()

    # Add conversation handler
    application.add_handler(ConversationHandler(
        entry_points=[CommandHandler('start', partial(start, app=app))],
        states={
            0: [MessageHandler(telegram.ext.filters.TEXT, partial(place_change, app=app))],
            1: [MessageHandler(telegram.ext.filters.TEXT, partial(update_threshold, app=app))]
        },
        fallbacks=[]
    ))

    application.run_polling(
    )


def stort(app):
    run(app)
