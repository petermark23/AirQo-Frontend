# Generated by Django 4.0.5 on 2022-07-13 19:59

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('career', '0003_rename_bullet_bulletpoint_bullet_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='career',
            name='unique_title',
            field=models.CharField(blank=True, max_length=100, null=True),
        ),
    ]
