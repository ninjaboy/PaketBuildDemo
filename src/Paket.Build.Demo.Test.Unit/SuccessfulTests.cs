using Xunit;

namespace Paket.Build.Demo.Test.Unit
{
    public class SuccessfulTests
    {
        [Fact]
        public void TestOk()
        {
            Assert.True(true, "because true is the only true");
        }
    }
}
