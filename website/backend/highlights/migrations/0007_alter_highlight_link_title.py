# Generated by Django 4.1.1 on 2023-03-01 14:27

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('highlights', '0006_alter_highlight_title'),
    ]

    operations = [
        migrations.AlterField(
            model_name='highlight',
            name='link_title',
            field=models.CharField(blank=True, max_length=20),
        ),
    ]