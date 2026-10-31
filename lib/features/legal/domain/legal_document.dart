class LegalSection {
  const LegalSection({required this.title, required this.body});

  final String title;
  final String body;
}

enum LegalDocument {
  privacyPolicy,
  termsAndConditions,
  accountDeletion;

  String get title => switch (this) {
        LegalDocument.privacyPolicy => 'Kebijakan Privasi',
        LegalDocument.termsAndConditions => 'Syarat & Ketentuan',
        LegalDocument.accountDeletion => 'Penghapusan Akun',
      };

  String get path => switch (this) {
        LegalDocument.privacyPolicy => '/legal/privacy',
        LegalDocument.termsAndConditions => '/legal/terms',
        LegalDocument.accountDeletion => '/legal/account-deletion',
      };

  List<LegalSection> get sections => switch (this) {
        LegalDocument.privacyPolicy => const [
            LegalSection(
              title: 'Privacy Policy',
              body:
                  '''This privacy policy applies to the PILAH app for mobile devices, together with any related services operated by Ilma Ainur (collectively, the "Application"). Ilma Ainur is hereby referred to as the "Service Provider".''',
            ),
            LegalSection(
              title: 'Information Collection and Use',
              body:
                  '''The Application collects information when you download and use it. This information may include information such as
• Your device's Internet Protocol address
• The pages of the Application that you visit, the time and date of your visit, the time spent on those pages
• The time spent on the Application
• your mobile operating system you use''',
            ),
            LegalSection(
              title: 'Cookies and tracking technologies',
              body:
                  '''The Application or its third-party SDKs may use cookies, SDKs, pixels, and similar technologies to support functionality, analytics, or service delivery. Where required by applicable law, the Service Provider will obtain consent before using non-essential tracking technologies.''',
            ),
            LegalSection(
              title: 'Your Rights',
              body:
                  '''You may request access to, correction of, or deletion of your personal data held by the Service Provider. To exercise these rights, or to withdraw consent where processing is based on consent, contact the Service Provider at banksampahpilah@gmail.com.''',
            ),
            LegalSection(
              title: 'Your California privacy rights (CCPA/CPRA)',
              body:
                  '''If you are a California resident, you have the right to know what personal information is collected, the right to delete personal information, the right to opt out of the sale or sharing of personal information, and the right to non-discrimination for exercising these rights. To exercise your CCPA/CPRA rights, contact the Service Provider at banksampahpilah@gmail.com.
The Service Provider may use the information you provide to send important information, required notices, and, where permitted by law, marketing communications.
For a better experience while using the Application, the Service Provider may require you to provide certain personally identifiable information, including but not limited to Email, phone number. The information the Service Provider requests will be retained and used as described in this privacy policy.''',
            ),
            LegalSection(
              title: 'Third Party Access',
              body:
                  '''Only aggregated, anonymized data is periodically transmitted to external services to aid the Service Provider in improving the Application and their service. The Service Provider may share your information with third parties in the ways that are described in this privacy statement.''',
            ),
            LegalSection(
              title: 'International Data Transfers',
              body:
                  '''The Service Provider or its third-party service providers may transfer personal data to countries outside your country of residence, including outside the European Economic Area (EEA). Where applicable law requires safeguards for international transfers, the Service Provider will use appropriate mechanisms.
• Standard Contractual Clauses (SCCs) approved by the European Commission
• Adequacy decisions or other legally recognized transfer mechanisms
• Your consent, where required and legally permitted
Data protection laws in other countries may differ from those in your jurisdiction. Where required by law, the Service Provider will apply appropriate safeguards and obtain any consent required for the transfer.
The Service Provider may disclose User Provided and Automatically Collected Information:
• as required by law, such as to comply with a subpoena, or similar legal process;
• when they believe in good faith that disclosure is necessary to protect their rights, protect your safety or the safety of others, investigate fraud, or respond to a government request;
• with their trusted services providers who work on their behalf, do not have an independent use of the information the Service Provider discloses to them, and have agreed to adhere to the rules set forth in this privacy statement.''',
            ),
            LegalSection(
              title: 'Opt-Out Rights',
              body:
                  '''You can stop further collection of information from your mobile device by uninstalling the Application. Uninstalling will stop the Application from collecting data from your device, but it does not automatically delete information that has already been transmitted to the Service Provider or to third parties.
To request deletion of your personal data, to withdraw consent, or to exercise any of your rights, contact the Service Provider at banksampahpilah@gmail.com.''',
            ),
            LegalSection(
              title: 'Data Retention Policy',
              body:
                  '''The Service Provider retains personal data based on its necessity for the stated purposes:
• User Provided Data: Retained for the duration of your use of the Application plus 12 months thereafter, unless longer retention is required by law
• Automatically Collected Data: Retained for up to 24 months from collection, unless longer retention is required for legal compliance
• Aggregated and Anonymized Data: Retained indefinitely as it no longer identifies you
• Data required for legal compliance: Retained as long as required by applicable law
You may request deletion of your personal data, subject to any legal obligation to retain it. If you want the Service Provider to delete User Provided Data submitted through the Application, please contact them at banksampahpilah@gmail.com. Please note that some User Provided Data may be required for the Application to function properly.''',
            ),
            LegalSection(
              title: 'Children',
              body:
                  '''The Application is not intended for children under 13 years of age, or such higher age as required by applicable law. The Service Provider does not knowingly solicit data from children or market the Application to them.
The Service Provider does not knowingly collect personally identifiable information from children. The Service Provider encourages all children to never submit any personally identifiable information through the Application and/or Services. The Service Provider encourages parents and legal guardians to monitor their children's Internet usage and to help enforce this Policy by instructing their children never to provide personally identifiable information through the Application and/or Services without their permission. If you have reason to believe that a child has provided personally identifiable information to the Service Provider through the Application and/or Services, please contact the Service Provider so that they will be able to take the necessary actions. If you are under 13 years of age, your parent or guardian must provide consent on your behalf where permitted by law.''',
            ),
            LegalSection(
              title: 'Security',
              body:
                  '''The Service Provider is concerned about safeguarding the confidentiality of your information. The Service Provider provides physical, electronic, and procedural safeguards to protect information the Service Provider processes and maintains.''',
            ),
            LegalSection(
              title: 'Data Breach Notification',
              body:
                  '''If a data breach occurs that affects your personal data, the Service Provider will notify you in accordance with applicable legal requirements, including, where required, providing information about the nature of the breach and the steps being taken to address it.''',
            ),
            LegalSection(
              title: 'Changes',
              body:
                  '''The Service Provider may update this Privacy Policy from time to time. The Service Provider will notify you of material changes by posting the updated Privacy Policy with an effective date. Where required by law, the Service Provider will seek your consent to material changes before they take effect.
Previous versions of this Privacy Policy will be maintained and made available upon request by contacting the Service Provider at banksampahpilah@gmail.com.
This privacy policy is effective as of 2026-08-19''',
            ),
            LegalSection(
              title: 'Your Consent',
              body:
                  '''Where processing is based on consent, you provide that consent by affirmatively opting in to the relevant feature or action. You may withdraw consent at any time without affecting processing carried out before withdrawal. Processing based on other lawful bases is carried out as described above.''',
            ),
            LegalSection(
              title: 'Contact Us',
              body:
                  '''If you have any questions regarding privacy while using the Application, or have questions about the practices, please contact the Service Provider via email at banksampahpilah@gmail.com.''',
            ),
            LegalSection(
              title: 'This privacy policy page was generated by',
              body:
                  'App Privacy Policy Generator (https://app-privacy-policy-generator.nisrulz.com/).',
            ),
          ],
        LegalDocument.termsAndConditions => const [
            LegalSection(
              title: 'Penggunaan PILAH',
              body:
                  '''PILAH membantu pengguna mengakses informasi dan mencatat kegiatan bank sampah, termasuk keanggotaan, harga sampah, setoran, saldo, dan riwayat transaksi. Fitur dan data yang dapat diakses mengikuti peran akun serta keanggotaan pada bank sampah.''',
            ),
            LegalSection(
              title: 'Akun dan informasi',
              body:
                  '''Gunakan informasi yang benar dan perbarui bila ada perubahan. Jaga keamanan akun dan metode masuk yang kamu gunakan. Jangan membagikan kata sandi atau kode OTP kepada siapa pun.''',
            ),
            LegalSection(
              title: 'Akses akun dan data',
              body:
                  '''Gunakan akun hanya untuk fitur dan data yang menjadi kewenangan peranmu. Jangan mengakses, mengubah, atau menghapus data pengguna atau bank sampah lain tanpa izin. Jangan memalsukan catatan bank sampah atau mengganggu layanan PILAH.''',
            ),
            LegalSection(
              title: 'Harga, saldo, dan transaksi',
              body:
                  '''Harga jenis sampah dikelola oleh bank sampah terkait. Nilai setoran dan saldo mengikuti catatan transaksi yang dimasukkan oleh pengelola. Periksa rincian yang tampil. Jika ada perbedaan, catat tanggal dan detail transaksi lalu hubungi bank sampah terkait agar catatan dapat diperiksa.''',
            ),
            LegalSection(
              title: 'Bantuan dan koreksi catatan',
              body:
                  '''Untuk pertanyaan atau keberatan mengenai harga, transaksi, saldo, atau keanggotaan, hubungi pengurus bank sampah yang bersangkutan. Untuk bantuan penggunaan aplikasi, email banksampahpilah@gmail.com. Sertakan tanggal dan rincian yang relevan; jangan kirim kata sandi atau kode OTP.''',
            ),
            LegalSection(
              title: 'Data pribadi dan penghapusan akun',
              body:
                  '''Cara PILAH menggunakan dan menyimpan data pribadi dijelaskan dalam Kebijakan Privasi. Untuk meminta penghapusan akun dan data terkait, buka Informasi & legal, lalu pilih Penghapusan Akun dan ikuti petunjuknya.''',
            ),
            LegalSection(
              title: 'Pembaruan',
              body:
                  'Syarat dan ketentuan ini dapat diperbarui. Perubahan akan ditampilkan pada halaman ini.',
            ),
          ],
        LegalDocument.accountDeletion => const [
            LegalSection(
              title: 'Kirim permintaan',
              body:
                  '''Untuk meminta penghapusan akun PILAH, kirim email ke banksampahpilah@gmail.com dengan subjek "Permintaan penghapusan akun PILAH". Sertakan alamat email yang digunakan saat mendaftar. Nama dan nama bank sampah dapat disertakan bila membantu tim menemukan akun.''',
            ),
            LegalSection(
              title: 'Verifikasi pemilik akun',
              body:
                  '''Permintaan ditangani secara manual. Tim dapat meminta konfirmasi melalui alamat email terdaftar untuk memastikan permintaan berasal dari pemilik akun. Kamu tetap dapat mengirim permintaan melalui email meskipun tidak dapat masuk ke aplikasi. Jangan kirim kata sandi atau kode OTP.''',
            ),
            LegalSection(
              title: 'Data yang ditinjau',
              body:
                  '''Permintaan mencakup akun PILAH dan data pribadi yang terkait. Tim akan meninjau data profil dan akses akun bersama data keanggotaan serta catatan saldo, setoran, pencairan, dan transaksi yang terhubung dengan bank sampah. Sebagian catatan mungkin perlu dipertahankan untuk menjaga riwayat transaksi atau memenuhi kewajiban hukum. Jika ada data yang dipertahankan, tim akan menjelaskan jenis data, alasan, dan masa retensinya sesuai Kebijakan Privasi dan kewajiban hukum yang berlaku.''',
            ),
            LegalSection(
              title: 'Waktu penanganan',
              body:
                  '''Mengirim email tidak langsung menghapus akun. Tim akan meninjau permintaan, lalu mengonfirmasi cakupan penghapusan dan perkiraan waktu penanganan melalui email. Penghapusan aplikasi dari perangkat juga tidak otomatis menghapus akun atau data yang telah dikirim ke PILAH.''',
            ),
          ],
      };
}
