"""
Gets newest Netto coupons and sends them as email or updates Firebase Database
"""

from bs4 import BeautifulSoup
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore
from sendgrid import SendGridAPIClient
from python_http_client.exceptions import HTTPError
from sendgrid.helpers.mail import (Mail, Attachment, FileContent, FileName, FileType, Disposition, ContentId)
from selenium import webdriver
from urllib.request import Request, urlopen
import base64
import os
import re
import time


def resource_path(relative_path):
    return str(os.path.join(os.path.dirname(__file__), relative_path))


load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '.env'))

SEND_EMAIL = False
UPDATE_FIREBASE = True

LABELS = [
    '1x 15 % auf einen Artikel',
    '3x 10 % auf je einen Artikel',
    '1x 20 % auf Obst',
    '1x 20 % auf je einen Molkereiartikel',
    '1x 20 % auf je einen Fleisch',
    ]

NUMBERS = [1, 3, 1, 1, 1]  # how often to redeem
DISCOUNTS = [15, 10, 20, 20, 20]  # in percent
TYPES = ['', '', 'Obst & Gemüse', 'Molkereiartikel', 'Fleischartikel']

TITLES = [f'{n}x <b>{d}%</b> {t}' for n, d, t in zip(NUMBERS, DISCOUNTS, TYPES)]

SENDGRID_API_KEY = os.environ.get('SENDGRID_API_KEY')
FROM_EMAIL = os.environ.get('FROM_EMAIL')


def main():
    href = get_href_of_current_netto_page()
    print(href)
    barcode_urls = get_barcode_urls(href)
    if UPDATE_FIREBASE:
        update_firebase(barcode_urls)
    if SEND_EMAIL:
        subject = get_subject(href)
        html = get_html(barcode_urls)
        attachments = get_attachments_from_urls(barcode_urls)
        for email in load_emails():
            send_email(email, subject, html, attachments)


def load_emails():
    try:
        with open(resource_path('.emails')) as file:
            return file.readlines()
    except FileNotFoundError:
        return []


def get_href_of_current_netto_page():
    url = 'https://www.mydealz.de/search?q=Netto%20Rabatt%20Coupons'  # search for Netto coupons
    soup = get_page_with_selenium(url)
    threads = soup.find_all('a', class_='thread-link', href=True)  # all posts share this class name
    for a in threads:
        if 'rabatt-coupons' in a['href']:
            return a['href']


def get_page_with_selenium(url):
    driver = webdriver.Chrome()
    driver.get(url)
    time.sleep(2)  # allow some time to load the page
    soup = BeautifulSoup(driver.page_source, 'lxml')
    return soup


def get_barcode_urls(url):
    soup = get_page_with_selenium(url)
    txt = str(soup)
    links = []
    for label in LABELS:
        match = re.search(label, txt)
        if not match:
            # Try to find typos where one character was left out
            for i in range(1, len(label) - 1):
                match = re.search(label[:i] + label[i + 1:], txt)
                if match:
                    break
        if match:
            match = re.search(r'src="(.*?)"', txt[match.start():])
            links.append(match.group(1))
        else:
            links.append('Not found!')
    print(links)
    return links


def get_subject(url):
    kw = find_in_url(url, r'kw\d\d')
    week = find_in_url(url, r'\d{4}-\d{4}')
    return f'Netto Rabatt Coupons {kw.upper()} ({week[:2]}.{week[2:4]}. - {week[5:7]}.{week[7:9]}.)'


def find_in_url(s, pattern):
    match = re.search(pattern, s)
    return match.group()


def get_html(links):
    html = '<html><body>'
    gap = '<br>' * 10
    for idx, link in enumerate(links):
        html += f'{gap}<center><font size="+1">{TITLES[idx]}</font></center><br>' \
                f'<a href="{link}"><img src="cid:Barcode_{idx + 1}"/></a>{gap}'
    html += '</body></html>'
    return html


def get_attachments_from_urls(urls):
    attachments = []

    # Add attachments from urls
    base64images = [load_base64_image(url=url) for url in urls]
    for idx, barcode in enumerate(base64images):
        a = Attachment(FileContent(barcode),
                       FileName(f'Barcode_{idx + 1}.jpg'),
                       FileType('image/jpg'),
                       Disposition('inline'),
                       ContentId(f'Barcode_{idx + 1}'))
        attachments.append(a)

    # Add attachments from data folder
    data = resource_path('data')
    base64images = [load_base64_image(filepath=f'{data}/{img}') for img in os.listdir(data) if img.endswith('.jpg')]
    for idx, img in enumerate(base64images):
        a = Attachment(FileContent(img),
                       FileName(f'Img_{idx + 1}.jpg'),
                       FileType('image/jpg'),
                       Disposition('inline'),
                       ContentId(f'Img_{idx + 1}'))
        attachments.append(a)
    return attachments


def load_base64_image(url=None, filepath=None):
    if url:
        req = Request(url=url, headers={'User-Agent': 'Mozilla/5.0'})
        img_in_bytes = urlopen(req).read()
    elif filepath:
        with open(filepath, 'rb') as file:
            img_in_bytes = file.read()
    else:
        return
    img_in_base64 = base64.b64encode(img_in_bytes).decode()
    return img_in_base64


def send_email(to_email, subject, html_content, attachments=None):
    message = Mail(
        from_email=FROM_EMAIL,
        to_emails=to_email,
        subject=subject,
        html_content=html_content
    )

    if attachments is not None:
        for attached_file in attachments:
            message.attachment = attached_file

    sg = SendGridAPIClient(SENDGRID_API_KEY)
    try:
        sg.send(message)
        print(f'Email sent to {to_email}')
    except HTTPError as e:
        print(e.to_dict)


def update_firebase(links):
    cred = credentials.Certificate(resource_path('firebase.json'))
    firebase_admin.initialize_app(cred)
    db = firebase_admin.firestore.client()
    collection_ref = db.collection('Coupons')

    for idx, link in enumerate(links):
        document_id = str(idx)
        doc_ref = collection_ref.document(document_id)
        data = {
            'number': NUMBERS[idx],
            'discount': DISCOUNTS[idx],
            'type': TYPES[idx],
            'base64ImageString': load_base64_image(url=link),
        }
        doc_ref.set(data)
        # print(doc_ref.get().to_dict())  # print data
    print('Firebase Database successfully updated!')


if __name__ == '__main__':
    main()
