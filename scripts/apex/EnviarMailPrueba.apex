Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
List<Messaging.SingleEmailMessage> mailsToSend = new List<Messaging.SingleEmailMessage>();


EmailTemplate templateMail = [
			SELECT ID, Name, Subject, Body, FolderId, FolderName, HtmlValue
			FROM EmailTemplate
			WHERE name = 'NT_B2 Documentación completa para baja' limit 1
		];

mail.setToAddresses(new String[]{'victor.flores@elara.com.mx'});


mail.setWhatId('a0y3J000002ZZ4LQAW');
mail.setTemplateId(templateMail.Id);
mail.setTreatBodiesAsTemplate(true);
mail.setSubject(templateMail.Subject);
mail.setHtmlBody(templateMail.HTMLValue);
String texto = templateMail.Body;
mail.setPlainTextBody(texto);
mail.setSenderDisplayName('Test');
mailsToSend.add(mail);
Messaging.sendEmail(mailsToSend);
