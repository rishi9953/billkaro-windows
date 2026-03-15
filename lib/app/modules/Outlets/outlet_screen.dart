import 'package:billkaro/app/modules/Outlets/outlet_controller.dart';
import 'package:billkaro/config/config.dart';

class CreateOutletScreen extends StatelessWidget {
  final CreateOutletController controller = Get.put(CreateOutletController());

  CreateOutletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,

        title: Text('Create New Outlet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Form(
        key: controller.formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Outlet Name Field
                    _buildLabel('Outlet Name', isRequired: true),
                    SizedBox(height: 8),
                    TextFormField(
                      decoration: _inputDecoration('Enter the outlet name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter outlet name';
                        }
                        return null;
                      },
                      onChanged: (value) => controller.outletName.value = value,
                    ),
                    SizedBox(height: 20),

                    // Type Dropdown
                    _buildLabel('Type', isRequired: true),
                    SizedBox(height: 8),
                    Obx(
                      () => DropdownButtonFormField<String>(
                        value: controller.selectedType.value,
                        decoration: _inputDecoration('Select the type'),
                        items: controller.typeOptions.map((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value));
                        }).toList(),
                        onChanged: (newValue) {
                          controller.selectedType.value = newValue!;
                        },
                      ),
                    ),
                    SizedBox(height: 20),

                    // Seating Capacity Dropdown
                    _buildLabel('Seating Capacity'),
                    SizedBox(height: 8),
                    Obx(
                      () => DropdownButtonFormField<String>(
                        value: controller.selectedCapacity.value,
                        decoration: _inputDecoration('Select the capacity'),
                        items: controller.capacityOptions.map((opt) {
                          return DropdownMenuItem<String>(
                            value: opt['value'],
                            child: Text(opt['label']!),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          controller.selectedCapacity.value = newValue!;
                        },
                      ),
                    ),
                    SizedBox(height: 20),

                    // How old is the outlet Dropdown
                    _buildLabel('How old is the outlet?'),
                    SizedBox(height: 8),
                    Obx(
                      () => DropdownButtonFormField<String>(
                        value: controller.selectedAge.value,
                        decoration: _inputDecoration('Select the age'),
                        items: controller.ageOptions.map((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value));
                        }).toList(),
                        onChanged: (newValue) {
                          controller.selectedAge.value = newValue!;
                        },
                      ),
                    ),
                    SizedBox(height: 20),

                    // Outlet Address Field
                    _buildLabel('Outlet Address'),
                    SizedBox(height: 8),
                    TextFormField(decoration: _inputDecoration('Enter the outlet address'), maxLines: 3, onChanged: (value) => controller.outletAddress.value = value),
                  ],
                ),
              ),
            ),

            // Create Outlet Button (Fixed at bottom)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => controller.createOutlet(),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Create Outlet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
        children: isRequired
            ? [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
              ]
            : [],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColor.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}
