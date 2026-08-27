part of 'inventory_dialogs.dart';

Future<void> showAddSupplierDialog(InventoryController c) async {
  await _showSupplierDialog(c);
}

Future<void> showEditSupplierDialog(
  InventoryController c,
  SupplierData supplier,
) async {
  await _showSupplierDialog(c, supplier: supplier);
}

Future<void> _showSupplierDialog(
  InventoryController c, {
  SupplierData? supplier,
}) async {
  final loc = AppLocalizations.of(Get.context!)!;
  final isEdit = supplier != null;
  if (!isEdit && c.suppliers.isEmpty) {
    // Best-effort only; do not block dialog open.
    // ignore: discarded_futures
    c.loadSuppliers();
  }

  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController(text: supplier?.name ?? '');
  final vendorNo = isEdit ? (supplier.vendorNo ?? '') : c.generateVendorNo();
  final vendorNoCtrl = TextEditingController(text: vendorNo);
  final companyCtrl = TextEditingController(
    text: supplier?.displayCompany ?? '',
  );
  final phoneCtrl = TextEditingController(
    text: _normalizePhone(supplier?.phone),
  );
  final emailCtrl = TextEditingController(text: supplier?.email ?? '');
  final registerAddressCtrl = TextEditingController(
    text: (supplier?.addressLine1 ?? '').trim().isNotEmpty
        ? supplier!.addressLine1!
        : (supplier?.address ?? ''),
  );
  final cityCtrl = TextEditingController(text: supplier?.city ?? '');
  final stateCtrl = TextEditingController(text: supplier?.state ?? '');
  final pinCodeCtrl = TextEditingController(text: supplier?.pinCode ?? '');
  final shippingAddressCtrl = TextEditingController(
    text: supplier?.shippingAddress ?? '',
  );
  final gstCtrl = TextEditingController(text: supplier?.gstNumber ?? '');
  final fssaiCtrl = TextEditingController(text: supplier?.fssaiLicNo ?? '');
  final panCtrl = TextEditingController(text: supplier?.pan ?? '');
  final msmeCtrl = TextEditingController(text: supplier?.msmeNumber ?? '');
  final tanCtrl = TextEditingController(text: supplier?.tan ?? '');
  final cinCtrl = TextEditingController(text: supplier?.cin ?? '');
  final tcsCtrl = TextEditingController(
    text: supplier?.tcsPercent != null ? '${supplier!.tcsPercent}' : '',
  );

  final registeredUnderGst = (supplier?.registeredUnderGst ?? false).obs;
  final supplierType = (supplier?.supplierType ?? 'both').obs;
  final shippingExpanded =
      ((supplier?.shippingAddress ?? '').trim().isNotEmpty).obs;
  final selectedFileName = (_fileNameFromUrl(supplier?.documentUrl) ?? '').obs;
  File? selectedFile;
  String? documentUrl = supplier?.documentUrl;

  final gstinVerify = GstinVerifyHelper();
  final contactVerifier = SupplierContactVerifier(
    outletId: c.outletId,
    editingSupplierId: supplier?.id,
    originalEmail: supplier?.email,
    originalPhone: supplier?.phone,
  );

  if (isEdit) {
    gstinVerify.markSavedFromServer(supplier.gstNumber);
    final existingPhone = _normalizePhone(supplier.phone);
    if (existingPhone.length == 10) {
      contactVerifier.onPhoneChanged(existingPhone);
    }
    final existingEmail = (supplier.email ?? '').trim();
    if (existingEmail.isNotEmpty) {
      contactVerifier.onEmailChanged(existingEmail);
    }
  }

  void handleGstinChanged() => gstinVerify.resetIfChanged(gstCtrl.text);
  gstCtrl.addListener(handleGstinChanged);

  Future<void> verifySupplierGstin() async {
    final details = await gstinVerify.verify(
      gstCtrl.text,
      onError: ({title, required description}) =>
          showError(title: title, description: description),
      onSuccess: ({title, required description}) =>
          showSuccess(title: title, description: description),
    );

    if (details == null || !gstinVerify.isGstinVerified.value) return;

    if (nameCtrl.text.trim().isEmpty && details.legalName != null) {
      nameCtrl.text = details.legalName!;
    }
    formKey.currentState?.validate();
  }

  Future<void> pickSupplierDocument() async {
    const typeGroup = XTypeGroup(
      label: 'Documents',
      extensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp', 'doc', 'docx'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    selectedFile = File(file.path);
    selectedFileName.value = file.name;
  }

  Future<String?> uploadSupplierDocument() async {
    if (selectedFile == null) return documentUrl;
    showAppLoader();
    try {
      final response = await MediaApi().uploadImage(
        file: selectedFile!,
        folderName: 'suppliers',
        userId: c.userId,
        outletId: c.outletId,
      );
      final url = response?.data['url']?.toString();
      if (url == null || url.isEmpty) {
        showError(description: 'Failed to upload document');
        return null;
      }
      return url;
    } finally {
      dismissAllAppLoader();
    }
  }

  await showInventoryEndDrawer(
    title: isEdit ? loc.edit_supplier : loc.add_supplier,
    width: 520,
    body: Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _supplierSectionTitle('1. Details'),
          TextFormField(
            controller: nameCtrl,
            decoration: InputDecoration(
              label: _requiredLabel('Name'),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return loc.please_enter_supplier_name;
              }
              return null;
            },
          ),
          _supplierFieldGap(),
          TextFormField(
            controller: vendorNoCtrl,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Vendor No',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: const OutlineInputBorder(),
            ),
          ),
          _supplierFieldGap(),
          TextFormField(
            controller: companyCtrl,
            decoration: InputDecoration(
              label: _requiredLabel('Company'),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Please enter company name';
              }
              return null;
            },
          ),
          _supplierFieldGap(),
          Obx(
            () => TextFormField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: _phoneInputFormatters,
              maxLength: 10,
              onChanged: contactVerifier.onPhoneChanged,
              decoration: InputDecoration(
                label: _requiredLabel(loc.phone_label),
                border: const OutlineInputBorder(),
                suffixIcon: contactVerifier.buildPhoneSuffixIcon(),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                helperText: contactVerifier.buildPhoneHelperText(),
                helperStyle: TextStyle(
                  color: contactVerifier.buildPhoneHelperColor(),
                ),
                errorMaxLines: 2,
                helperMaxLines: 2,
              ),
              validator: (value) => contactVerifier.validatePhone(
                value,
                emptyMessage: loc.please_enter_phone_number,
              ),
            ),
          ),
          _supplierFieldGap(),
          Obx(
            () => TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              onChanged: contactVerifier.onEmailChanged,
              decoration: InputDecoration(
                label: _requiredLabel(loc.email),
                border: const OutlineInputBorder(),
                suffixIcon: contactVerifier.buildEmailSuffixIcon(),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                helperText: contactVerifier.buildEmailHelperText(),
                helperStyle: TextStyle(
                  color: contactVerifier.buildEmailHelperColor(),
                ),
                errorMaxLines: 2,
                helperMaxLines: 2,
              ),
              validator: contactVerifier.validateEmail,
            ),
          ),
          _supplierFieldGap(),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Registered Under GST',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Obx(
            () => RadioGroup<bool>(
              groupValue: registeredUnderGst.value,
              onChanged: (value) {
                if (value == null) return;
                registeredUnderGst.value = value;
                if (!value) {
                  gstCtrl.clear();
                  gstinVerify.markSavedFromServer('');
                }
              },
              child: Row(
                children: const [
                  Expanded(
                    child: RadioListTile<bool>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('Yes'),
                      value: true,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('No'),
                      value: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Obx(() {
            if (!registeredUnderGst.value) return const SizedBox.shrink();
            return Column(
              children: [
                TextFormField(
                  controller: gstCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    label: _requiredLabel(loc.gst_number_label),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (!registeredUnderGst.value) return null;
                    final gst = (value ?? '').trim().toUpperCase();
                    if (gst.isEmpty) return 'Please enter GST number';
                    if (gstinVerify.requiresVerification(gst)) {
                      return 'Please verify GSTIN before saving supplier';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                GstinVerifyRow(
                  helper: gstinVerify,
                  onVerify: verifySupplierGstin,
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          _supplierSectionTitle('2. Address Details'),
          TextFormField(
            controller: registerAddressCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              label: _requiredLabel('Register Address'),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return loc.please_enter_address;
              }
              return null;
            },
          ),
          _supplierFieldGap(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: stateCtrl,
                  decoration: InputDecoration(
                    label: _requiredLabel(loc.state_label),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return loc.please_enter_state;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: cityCtrl,
                  decoration: InputDecoration(
                    label: _requiredLabel('City'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Please enter city';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          _supplierFieldGap(),
          TextFormField(
            controller: pinCodeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: _pinCodeInputFormatters,
            decoration: InputDecoration(
              label: _requiredLabel(loc.pincode_label),
              border: const OutlineInputBorder(),
              counterText: '',
            ),
            validator: (value) {
              final pin = (value ?? '').trim();
              if (pin.isEmpty) return loc.please_enter_pincode;
              if (pin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pin)) {
                return loc.please_enter_valid_pincode;
              }
              return null;
            },
          ),
          _supplierFieldGap(),
          Obx(
            () => Theme(
              data: Theme.of(
                Get.context!,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: shippingExpanded.value,
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 4),
                title: const Text(
                  'Shipping Address',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onExpansionChanged: (expanded) {
                  shippingExpanded.value = expanded;
                },
                children: [
                  TextFormField(
                    controller: shippingAddressCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      label: _optionalLabel('Shipping Address'),
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _supplierSectionTitle('3. Other Details'),
          TextFormField(
            controller: fssaiCtrl,
            decoration: InputDecoration(
              label: _optionalLabel('FSSAI Lic No'),
              border: const OutlineInputBorder(),
            ),
          ),
          _supplierFieldGap(),
          TextFormField(
            controller: panCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              label: _optionalLabel('PAN'),
              border: const OutlineInputBorder(),
            ),
          ),
          _supplierFieldGap(),
          TextFormField(
            controller: msmeCtrl,
            decoration: InputDecoration(
              label: _optionalLabel('MSME Number'),
              border: const OutlineInputBorder(),
            ),
          ),
          _supplierFieldGap(),
          TextFormField(
            controller: tanCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              label: _optionalLabel('TAN'),
              border: const OutlineInputBorder(),
            ),
          ),
          _supplierFieldGap(),
          TextFormField(
            controller: cinCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              label: _optionalLabel('CIN'),
              border: const OutlineInputBorder(),
            ),
          ),
          _supplierFieldGap(),
          TextFormField(
            controller: tcsCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _numberInputFormatters,
            decoration: InputDecoration(
              label: _optionalLabel('Tax Collected at Source (TCS %)'),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.isEmpty) return null;
              final parsed = double.tryParse(text);
              if (parsed == null || parsed < 0 || parsed > 100) {
                return 'Enter a valid TCS % (0-100)';
              }
              return null;
            },
          ),
          _supplierFieldGap(),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Type',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Obx(
            () => RadioGroup<String>(
              groupValue: supplierType.value,
              onChanged: (value) {
                if (value != null) supplierType.value = value;
              },
              child: const Column(
                children: [
                  RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Both'),
                    value: 'both',
                  ),
                  RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Purchase'),
                    value: 'purchase',
                  ),
                  RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Sale'),
                    value: 'sale',
                  ),
                ],
              ),
            ),
          ),

          _supplierFieldGap(),
          Obx(
            () => OutlinedButton.icon(
              onPressed: pickSupplierDocument,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(
                selectedFileName.value.isEmpty
                    ? 'Upload File'
                    : selectedFileName.value,
              ),
            ),
          ),
        ],
      ),
    ),
    footerActions: [
      TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
      ElevatedButton(
        onPressed: () async {
          final isValid = formKey.currentState?.validate() ?? false;
          if (!isValid) return;

          final name = nameCtrl.text.trim();
          final company = companyCtrl.text.trim();
          final phone = _normalizePhone(phoneCtrl.text);
          final email = emailCtrl.text.trim();
          if (!await contactVerifier.ensurePhoneAvailable(phone)) return;
          if (!await contactVerifier.ensureEmailAvailable(email)) return;

          final registerAddress = registerAddressCtrl.text.trim();
          final city = cityCtrl.text.trim();
          final state = stateCtrl.text.trim();
          final pinCode = pinCodeCtrl.text.trim();
          final shippingAddress = shippingAddressCtrl.text.trim();
          final isGstRegistered = registeredUnderGst.value;
          final gst = isGstRegistered ? gstCtrl.text.trim().toUpperCase() : '';
          final tcsText = tcsCtrl.text.trim();
          final tcsPercent = tcsText.isEmpty ? null : double.tryParse(tcsText);

          final uploadedUrl = await uploadSupplierDocument();
          if (selectedFile != null && uploadedUrl == null) return;
          documentUrl = uploadedUrl ?? documentUrl;

          final address = [registerAddress, city, state, pinCode].join(', ');

          final payload = <String, dynamic>{
            'name': name,
            'company': company,
            'contactPerson': company,
            'vendorNo': vendorNoCtrl.text.trim(),
            'phone': phone,
            'email': email,
            'registeredUnderGst': isGstRegistered,
            'gstNumber': gst,
            'address': address,
            'addressLine1': registerAddress,
            'city': city,
            'state': state,
            'pinCode': pinCode,
            'shippingAddress': shippingAddress,
            'fssaiLicNo': fssaiCtrl.text.trim(),
            'pan': panCtrl.text.trim().toUpperCase(),
            'msmeNumber': msmeCtrl.text.trim(),
            'tan': tanCtrl.text.trim().toUpperCase(),
            'cin': cinCtrl.text.trim().toUpperCase(),
            'tcsPercent': tcsPercent,
            'supplierType': supplierType.value,
            'documentUrl': documentUrl ?? '',
          };

          final ok = isEdit
              ? await c.updateSupplier(supplier.id, payload)
              : await c.createSupplier(payload);
          if (ok) Get.back();
        },
        child: Text(loc.save),
      ),
    ],
  );

  await Future.delayed(const Duration(milliseconds: 350));
  gstCtrl.removeListener(handleGstinChanged);
  contactVerifier.dispose();
  gstCtrl.dispose();
  vendorNoCtrl.dispose();
  companyCtrl.dispose();
  nameCtrl.dispose();
  phoneCtrl.dispose();
  emailCtrl.dispose();
  registerAddressCtrl.dispose();
  cityCtrl.dispose();
  stateCtrl.dispose();
  pinCodeCtrl.dispose();
  shippingAddressCtrl.dispose();
  fssaiCtrl.dispose();
  panCtrl.dispose();
  msmeCtrl.dispose();
  tanCtrl.dispose();
  cinCtrl.dispose();
  tcsCtrl.dispose();
}
