import 'package:billkaro/app/modules/Regular%20customer/AddRegularCustomer/addregular_customer_controller.dart';
import 'package:billkaro/config/config.dart';

class ContactPickerSheet extends StatelessWidget {
  final controller = Get.find<AddCustomerController>();

  ContactPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Contact',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              onChanged: controller.searchContacts,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF5B8DEE)),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // None Option
          if (controller.contacts.isEmpty)
            InkWell(
              onTap: () {
                controller.selectContact(null);
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                color: AppColor.primary,
                child: Text(
                  'None',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Loading or Contact List
          Expanded(
            child: Obx(() {
              if (controller.isLoadingContacts.value) {
                return Center(
                  child: CircularProgressIndicator(color: Color(0xFF5B8DEE)),
                );
              }

              final displayContacts = controller.filteredContacts.isEmpty
                  ? controller.contacts
                  : controller.filteredContacts;

              if (controller.contacts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.contacts_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No contacts found',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: controller.fetchContacts,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (displayContacts.isEmpty &&
                  controller.searchQuery.value.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'No contacts match your search',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                physics: BouncingScrollPhysics(),
                itemCount: displayContacts.length,
                itemBuilder: (context, index) {
                  final contact = displayContacts[index];
                  final phones = contact.phones;

                  return InkWell(
                    onTap: () {
                      controller.selectContact(contact);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Contact Photo
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColor.primary,

                            backgroundImage: contact.photo != null
                                ? MemoryImage(contact.photo!)
                                : null,
                            child: contact.photo == null
                                ? Text(
                                    contact.displayName.isNotEmpty
                                        ? contact.displayName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                          ),
                          SizedBox(width: 12),
                          // Contact Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact.displayName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (phones.isNotEmpty)
                                  ...phones.map(
                                    (phone) => Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Text(
                                        phone.number,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
